import Combine
import Foundation

final class UserPreferences: ObservableObject {
    static let shared = UserPreferences()
    
    @Published var assemblyAIKey: String = ""
    @Published var openAIKey: String = ""
    @Published var editingConfig: EditingConfig = .default
    @Published var floatingOverlayEnabled: Bool = true
    @Published var activationHotkey: String = "Option+Space"
    
    private init() {
        loadFromKeychain()
    }
    
    private func loadFromKeychain() {
        guard let keys = KeychainService().loadAPIKeys() else { return }
        
        assemblyAIKey = keys.assemblyAI
        openAIKey = keys.openAI
    }
    
    func save() throws {
        let keys = APIKeys(assemblyAI: assemblyAIKey, openAI: openAIKey)
        try KeychainService().saveAPIKeys(keys)
    }
    
    func validateKeys() -> Bool {
        return !assemblyAIKey.isEmpty
    }
}
