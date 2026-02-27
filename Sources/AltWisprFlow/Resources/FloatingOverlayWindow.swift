import AppKit
import SwiftUI

final class FloatingOverlayWindow: NSWindow {
    static let shared = FloatingOverlayWindow()
    
    private var hostingView: NSHostingView<FloatingOverlayView>?
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: CGRect(x: 0, y: 0, width: 350, height: 120), styleMask: .borderless, backing: .buffered, defer: false)
        
        setupWindow()
        setupContent()
    }
    
    private func setupWindow() {
        isOpaque = false
        backgroundColor = .clear
        level = .floating
        isMovableByWindowBackground = false
        hasShadow = true
        ignoresMouseEvents = false
        animationBehavior = .none
        
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        setFrameOrigin(CGPoint(
            x: screenFrame.width - frame.width - 20,
            y: screenFrame.height - frame.height - 100
        ))
    }
    
    private func setupContent() {
        let viewModel = FloatingOverlayViewModel()
        let contentView = FloatingOverlayView(viewModel: viewModel)
        let hostingView = NSHostingView(rootView: contentView)
        
        hostingView.frame = contentRect
        contentView?.addSubview(hostingView)
        self.hostingView = hostingView
    }
    
    func show() {
        orderFront(nil)
        makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
    
    func hide() {
        orderOut(nil)
    }
}
