import AppKit
import Combine

enum HotkeyState {
    case idle
    case awaitingRelease
    case recordingHeld
    case awaitingSecondTap
    case latched
}

enum HotkeyAction {
    case start
    case stop
    case latched
}

final class HotkeyManager {
    static let shared = HotkeyManager()
    
    private let activatedSubject = PassthroughSubject<HotkeyAction, Never>()
    var activatedPublisher: AnyPublisher<HotkeyAction, Never> {
        activatedSubject.eraseToAnyPublisher()
    }
    
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    private var state: HotkeyState = .idle
    private var isFnCurrentlyDown = false
    private var timer: Timer?
    
    private init() {
        setupEventMonitors()
    }
    
    private func setupEventMonitors() {
        let eventMask = (1 << CGEventType.flagsChanged.rawValue)
        
        let callback: CGEventTapCallBack = { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
            guard type == .flagsChanged, let refcon = refcon else {
                return Unmanaged.passRetained(event)
            }
            
            let manager = Unmanaged<HotkeyManager>.fromOpaque(refcon).takeUnretainedValue()
            let flags = event.flags
            
            // Mask for the Fn key
            let isFnDown = flags.contains(.maskSecondaryFn)
            
            // If the state changed
            if isFnDown != manager.isFnCurrentlyDown {
                manager.isFnCurrentlyDown = isFnDown
                
                DispatchQueue.main.async {
                    if isFnDown {
                        manager.handleFnDown()
                    } else {
                        manager.handleFnUp()
                    }
                }
                
                // Return nil to swallow the event so the OS Emoji picker doesn't open
                return nil
            }
            
            return Unmanaged.passRetained(event)
        }
        
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: callback,
            userInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        )
        
        if let tap = eventTap {
            runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
            debugLog("[HotkeyManager] CGEventTap registered successfully")
        } else {
            debugLog("[HotkeyManager] Failed to register CGEventTap. Ensure Accessibility permissions are granted.")
        }
    }
    
    private func handleFnDown() {
        switch state {
        case .idle:
            state = .awaitingRelease
            emit(.start)
            startTimer(duration: 0.3) { [weak self] in
                self?.handleTimerExpired()
            }
        case .latched:
            state = .idle
            emit(.stop)
        case .awaitingSecondTap:
            cancelTimer()
        default:
            break
        }
    }
    
    private func handleFnUp() {
        switch state {
        case .recordingHeld:
            state = .idle
            emit(.stop)
        case .awaitingRelease:
            state = .awaitingSecondTap
            // Keep recording running (no stop emitted yet)
            startTimer(duration: 0.3) { [weak self] in
                self?.handleTimerExpired()
            }
        case .awaitingSecondTap:
            state = .latched
            emit(.latched)
        default:
            break
        }
    }
    
    private func handleTimerExpired() {
        switch state {
        case .awaitingRelease:
            // Timer Expires (300ms passed while holding)
            state = .recordingHeld
        case .awaitingSecondTap:
            // Second Timer Expires (No second tap arrived)
            state = .idle
            emit(.stop)
        default:
            break
        }
    }
    
    private func startTimer(duration: TimeInterval, action: @escaping () -> Void) {
        cancelTimer()
        timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
            action()
        }
    }
    
    private func cancelTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func emit(_ action: HotkeyAction) {
        debugLog("[HotkeyManager] Emitting action: \(action)")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if action == .start || action == .latched {
                FloatingOverlayWindow.shared.show()
            }
            self.activatedSubject.send(action)
        }
    }
    
    deinit {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let rlSource = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), rlSource, .commonModes)
            }
        }
        cancelTimer()
    }
}
