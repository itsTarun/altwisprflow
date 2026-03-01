import SwiftUI

struct MainMenuView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("AltWisprFlow")
                .font(.headline)
            
            Divider()
            
            Button(action: {
                openSettings()
            }) {
                HStack {
                    Image(systemName: "gearshape.fill")
                    Text("Settings...")
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                HStack {
                    Image(systemName: "power")
                    Text("Quit")
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(width: 200)
    }
    
    private func openSettings() {
        SettingsWindow.shared.show()
    }
}
