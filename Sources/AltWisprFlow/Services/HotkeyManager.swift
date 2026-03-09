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
    
    private var globalMonitor: Any?
    private var localMonitor: Any?
    
    private var state: HotkeyState = .idle
    private var isFnCurrentlyDown = false
    private var timer: Timer?
    
    private init() {
        setupEventMonitors()
    }
    
    private func setupEventMonitors() {
        // Global monitor - detects keys when OTHER apps are focused (requires Accessibility)
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
        }
        debugLog("[HotkeyManager] Global event monitor registered: \(globalMonitor != nil)")
        
        // Local monitor - detects keys when THIS app is focused
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
            return event
        }
        debugLog("[HotkeyManager] Local event monitor registered: \(localMonitor != nil)")
    }
    
    private func handleFlagsChanged(_ event: NSEvent) {
        let isDownNow = event.modifierFlags.contains(.function)
        if isDownNow != isFnCurrentlyDown {
            isFnCurrentlyDown = isDownNow
            if isDownNow {
                handleFnDown()
            } else {
                handleFnUp()
            }
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
        if let globalMonitor = globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
        if let localMonitor = localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
        cancelTimer()
    }
}
