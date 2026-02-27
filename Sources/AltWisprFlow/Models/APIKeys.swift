import Foundation

struct APIKeys: Codable {
    let assemblyAI: String
    let openAI: String
    
    static let empty = APIKeys(assemblyAI: "", openAI: "")
}