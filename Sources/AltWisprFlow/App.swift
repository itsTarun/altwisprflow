import SwiftUI

@main
struct AltWisprFlowApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    var body: some Scene {
        MenuBarExtra {
            MainMenuView()
        } label: {
            Image(systemName: "mic.fill")
                .renderingMode(.template)
                .foregroundColor(.white)
        }
        .menuBarExtraStyle(.window)
    }
}
