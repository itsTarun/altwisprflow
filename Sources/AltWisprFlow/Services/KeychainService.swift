import Foundation
import KeychainAccess

final class KeychainService {
    private let keychain = Keychain(service: "com.altwisprflow.app")
    
    func saveAPIKeys(_ keys: APIKeys) throws {
        let data = try JSONEncoder().encode(keys)
        try keychain
            .label("AltWisprFlow API Keys")
            .comment("API keys for AssemblyAI and OpenAI")
            .set(data, key: "api_keys")
    }
    
    func loadAPIKeys() -> APIKeys? {
        guard let data = try? keychain.getData("api_keys") else {
            return nil
        }
        return try? JSONDecoder().decode(APIKeys.self, from: data)
    }
    
    func hasAPIKeys() -> Bool {
        return loadAPIKeys() != nil
    }
    
    func deleteAPIKeys() throws {
        try keychain.remove("api_keys")
    }
}