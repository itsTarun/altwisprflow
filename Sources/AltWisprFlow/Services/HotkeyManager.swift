import AppKit
import Carbon
import Combine

final class HotkeyManager {
    static let shared = HotkeyManager()
    
    private var hotKeyRef: EventHotKeyRef?
    
    private let activatedSubject = PassthroughSubject<Void, Never>()
    var activatedPublisher: AnyPublisher<Void, Never> {
        activatedSubject.eraseToAnyPublisher()
    }
    
    private init() {
        setupCarbonHotkey()
    }
    
    /// Use Carbon RegisterEventHotKey for reliable system-level interception
    private func setupCarbonHotkey() {
        // Control+Option+Space
        let modifiers: UInt32 = UInt32(controlKey | optionKey)
        let keyCode: UInt32 = UInt32(kVK_Space)
        let hotKeyID = EventHotKeyID(signature: 0x464C4F57, id: 1)
        
        // Install event handler for hot key events
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, _) -> OSStatus in
                debugLog("[HotkeyManager] Carbon hotkey activated!")
                DispatchQueue.main.async {
                    FloatingOverlayWindow.shared.show()
                    HotkeyManager.shared.activatedSubject.send()
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            nil
        )
        debugLog("[HotkeyManager] Carbon event handler installed: \(status == noErr)")
        
        let regStatus = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        debugLog("[HotkeyManager] Carbon hotkey registered (Control+Option+Space): \(regStatus == noErr)")
    }
    
    /// Fallback NSEvent monitors
    private func setupEventMonitors() {
        // Global monitor - detects keys when OTHER apps are focused (requires Accessibility)
        let globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if flags.contains([.control, .option]),
               event.keyCode == 0x31 { // Space key
                debugLog("[HotkeyManager] Control+Option+Space detected (global)")
                DispatchQueue.main.async {
                    FloatingOverlayWindow.shared.show()
                    self?.activatedSubject.send()
                }
            }
        }
        debugLog("[HotkeyManager] Global event monitor registered: \(globalMonitor != nil)")
        
        // Local monitor - detects keys when THIS app is focused
        let localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            if flags.contains([.control, .option]),
               event.keyCode == 0x31 { // Space key
                debugLog("[HotkeyManager] Control+Option+Space detected (local)")
                DispatchQueue.main.async {
                    FloatingOverlayWindow.shared.show()
                    self?.activatedSubject.send()
                }
                return nil // consume the event
            }
            return event
        }
        debugLog("[HotkeyManager] Local event monitor registered: \(localMonitor != nil)")
    }
    
    func activate() {
        activatedSubject.send()
    }
    
    deinit {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
    }
}
