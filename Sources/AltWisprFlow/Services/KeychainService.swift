import Foundation
import KeychainAccess

final class KeychainService {
    private let service = "com.altwisprflow.app"
    private let keychain = Keychain(service: "com.altwisprflow.app")
    
    func saveAPIKeys(_ keys: APIKeys) throws {
        let data = try JSONEncoder().encode(keys)
        do {
            try keychain
                .label("AltWisprFlow API Keys")
                .comment("API keys for AssemblyAI and OpenAI")
                .set(data, key: "api_keys")
            debugLog("[KeychainService] Successfully saved API keys to Keychain")
        } catch {
            debugLog("[KeychainService] Error saving API keys: \(error)")
            throw error
        }
    }
    
    func loadAPIKeys() -> APIKeys? {
        do {
            guard let data = try keychain.getData("api_keys") else {
                debugLog("[KeychainService] No data found for key 'api_keys'")
                return nil
            }
            let keys = try JSONDecoder().decode(APIKeys.self, from: data)
            debugLog("[KeychainService] Successfully loaded API keys")
            return keys
        } catch {
            debugLog("[KeychainService] Error loading/decoding API keys: \(error)")
            return nil
        }
    }
    
    func hasAPIKeys() -> Bool {
        return loadAPIKeys() != nil
    }
    
    func deleteAPIKeys() throws {
        try keychain.remove("api_keys")  
    }
}