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
            
            HistorySettingsView(viewModel: viewModel)
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
                .tag(3)
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
                    Text("Control+Option+Space").tag("Control+Option+Space")
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
                VStack(alignment: .leading) {
                    Text("AssemblyAI (Required for Transcription)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    SecureField("AssemblyAI API Key", text: $viewModel.preferences.assemblyAIKey)
                }
                
                VStack(alignment: .leading) {
                    Text("OpenAI (Optional for Grammar/Polish)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    SecureField("OpenAI API Key", text: $viewModel.preferences.openAIKey)
                }
                
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

struct HistorySettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @ObservedObject private var overlayVM = FloatingOverlayViewModel.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("System Status:")
                    .font(.headline)
                Text(overlayVM.statusMessage)
                    .foregroundColor(overlayVM.statusMessage.contains("Error") ? .red : .green)
                Spacer()
                if !overlayVM.history.isEmpty {
                    Button("Clear History") {
                        overlayVM.clearHistory()
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(.bottom, 4)
            
            Divider()
            
            if overlayVM.history.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "mic.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No history yet")
                        .font(.headline)
                    Text("Your dictated text will appear here.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(overlayVM.history, id: \.self) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item)
                                .font(.body)
                                .textSelection(.enabled)
                            
                            HStack {
                                Text(Date(), style: .time)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Button(action: {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(item, forType: .string)
                                }) {
                                    Label("Copy", systemImage: "doc.on.doc")
                                        .font(.caption)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                        .padding(.vertical, 6)
                    }
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
