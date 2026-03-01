import AppKit
import SwiftUI

final class SettingsWindow: NSWindow {
    static let shared: SettingsWindow = {
        let window = SettingsWindow(
            contentRect: CGRect(x: 0, y: 0, width: 550, height: 450),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        return window
    }()
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        
        self.title = "AltWisprFlow Settings"
        self.center()
        self.isReleasedWhenClosed = false
        
        let contentView = SettingsView()
        let hostingView = NSHostingView(rootView: contentView)
        self.contentView = hostingView
    }
    
    func show() {
        self.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        debugLog("[SettingsWindow] Settings window shown")
    }
}
