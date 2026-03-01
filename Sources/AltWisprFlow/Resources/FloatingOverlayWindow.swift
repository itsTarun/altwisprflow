import AppKit
import SwiftUI

final class FloatingOverlayWindow: NSWindow {
    static let shared: FloatingOverlayWindow = {
        let window = FloatingOverlayWindow(
            contentRect: CGRect(x: 0, y: 0, width: 350, height: 120),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        return window
    }()
    
    private var hostingView: NSHostingView<FloatingOverlayView>?
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        
        setupWindow()
        setupContent()
        debugLog("[FloatingOverlayWindow] Window initialized")
    }
    
    private func setupWindow() {
        isOpaque = false
        backgroundColor = NSColor.black.withAlphaComponent(0.01) // Nearly transparent but allows events
        level = .screenSaver // Very high level to ensure visibility
        isMovableByWindowBackground = false
        hasShadow = false
        ignoresMouseEvents = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        setFrameOrigin(CGPoint(
            x: screenFrame.maxX - frame.width - 20,
            y: screenFrame.maxY - frame.height - 40
        ))
    }
    
    private func setupContent() {
        let viewModel = FloatingOverlayViewModel.shared
        let swiftUIView = FloatingOverlayView(viewModel: viewModel)
        let hostingView = NSHostingView(rootView: swiftUIView)
        
        // This makes sure the view gets sized correctly and handles clear background 
        self.contentView = hostingView
        self.hostingView = hostingView
    }
    
    func show() {
        debugLog("[FloatingOverlayWindow] Showing overlay")
        orderFront(nil)
        makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    func hide() {
        orderOut(nil)
    }
}
