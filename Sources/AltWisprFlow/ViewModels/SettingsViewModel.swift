import Combine
import Foundation

final class SettingsViewModel: ObservableObject {
    @Published var preferences = UserPreferences.shared
    @Published var showSuccessMessage = false
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        preferences.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    func save() {
        do {
            guard preferences.validateKeys() else {
                errorMessage = "AssemblyAI API key is required"
                return
            }
            
            try preferences.save()
            errorMessage = nil
            showSuccessMessage = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                self?.showSuccessMessage = false
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func testKeys() {
        // TODO: Test API keys are valid
    }
    
    func restoreDefaults() {
        preferences.editingConfig = .default
        showSuccessMessage = true
    }
}
