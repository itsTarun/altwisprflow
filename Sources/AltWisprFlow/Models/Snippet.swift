import Foundation

struct Snippet: Identifiable, Codable {
    let id: UUID
    let name: String
    let text: String
    let keywords: [String]
    
    init(id: UUID = UUID(), name: String, text: String, keywords: [String]) {
        self.id = id
        self.name = name
        self.text = text
        self.keywords = keywords
    }
}
