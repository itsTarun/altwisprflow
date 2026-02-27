import AppKit
import Carbon
import Combine

final class HotkeyManager {
    static let shared = HotkeyManager()
    
    private var eventHotKeyID = EventHotKeyID(signature: OSType("FLOW"), id: 1)
    
    private let activatedSubject = PassthroughSubject<Void, Never>()
    var activatedPublisher: AnyPublisher<Void, Never> {
        activatedSubject.eraseToAnyPublisher()
    }
    
    private init() {
        setupGlobalHotkey()
    }
    
    private func setupGlobalHotkey() {
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains(.option),
               event.keyCode == 0x31 { // Space key
                FloatingOverlayWindow.shared.show()
                self?.activatedSubject.send()
            }
        }
    }
    
    func activate() {
        activatedSubject.send()
    }
}
