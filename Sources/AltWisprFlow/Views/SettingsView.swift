import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        TabView {
            GeneralSettingsView(viewModel: viewModel)
                .tabItem { Label("General", systemImage: "gear") }
                .tag(0)
            
            APIKeysSettingsView(viewModel: viewModel)
                .tabItem { Label("API Keys", systemImage: "key") }
                .tag(1)
            
            EditingSettingsView(viewModel: viewModel)
                .tabItem { Label("Editing", systemImage: "textformat") }
                .tag(2)
        }
        .frame(width: 500, height: 400)
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct GeneralSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        Form {
            Section("Activation") {
                Picker("Hotkey", selection: $viewModel.preferences.activationHotkey) {
                    Text("Option+Space").tag("Option+Space")
                    Text("Command+Shift+D").tag("Command+Shift+D")
                    Text("Command+Space").tag("Command+Space")
                }
                
                Toggle("Show floating overlay", isOn: $viewModel.preferences.floatingOverlayEnabled)
            }
            
            Section("Appearance") {
                Button("Reset to defaults") {
                    viewModel.restoreDefaults()
                }
            }
        }
        .padding()
    }
}

struct APIKeysSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        Form {
            Section("API Keys") {
                SecureField("AssemblyAI API Key", text: $viewModel.preferences.assemblyAIKey)
                
                SecureField("OpenAI API Key", text: $viewModel.preferences.openAIKey)
                
                HStack {
                    Button("Save") {
                        viewModel.save()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Test") {
                        viewModel.testKeys()
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            if viewModel.showSuccessMessage {
                Section {
                    Label("Settings saved", systemImage: "checkmark.circle")
                        .foregroundColor(.green)
                }
            }
            
            if let error = viewModel.errorMessage {
                Section {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
    }
}

struct EditingSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        Form {
            Section("Text Processing") {
                Toggle("Remove filler words", isOn: $viewModel.preferences.editingConfig.removeFillerWords)
                Toggle("Correct grammar", isOn: $viewModel.preferences.editingConfig.correctGrammar)
                Toggle("Match tone per app", isOn: $viewModel.preferences.editingConfig.matchTone)
            }
            
            Section("Advanced") {
                Stepper("Max tokens: \(viewModel.preferences.editingConfig.maxTokens)", value: $viewModel.preferences.editingConfig.maxTokens, in: 50...1000)
                
                Slider(value: $viewModel.preferences.editingConfig.temperature, in: 0.0...1.0) {
                    Text("Creativity: \(String(format: "%.1f", viewModel.preferences.editingConfig.temperature))")
                }
            }
        }
        .padding()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
