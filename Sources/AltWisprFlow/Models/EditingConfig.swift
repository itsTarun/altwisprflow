import Foundation

struct EditingConfig: Codable {
    var maxTokens: Int
    var temperature: Double
    var removeFillerWords: Bool
    var correctGrammar: Bool
    var matchTone: Bool
    
    static let `default` = EditingConfig(
        maxTokens: 256,
        temperature: 0.1,
        removeFillerWords: true,
        correctGrammar: true,
        matchTone: false
    )
}
