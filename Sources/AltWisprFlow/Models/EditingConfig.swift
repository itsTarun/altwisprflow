import Foundation

struct EditingConfig: Codable {
    let maxTokens: Int
    let temperature: Double
    let removeFillerWords: Bool
    let correctGrammar: Bool
    let matchTone: Bool
    
    static let `default` = EditingConfig(
        maxTokens: 256,
        temperature: 0.1,
        removeFillerWords: true,
        correctGrammar: true,
        matchTone: false
    )
}
