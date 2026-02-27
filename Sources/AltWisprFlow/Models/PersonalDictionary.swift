import Foundation

struct PersonalDictionary: Codable {
    var words: Set<String>
    
    init(words: Set<String> = []) {
        self.words = words
    }
    
    mutating func addWord(_ word: String) {
        words.insert(word.lowercased())
    }
    
    mutating func removeWord(_ word: String) {
        words.remove(word.lowercased())
    }
    
    func contains(_ word: String) -> Bool {
        return words.contains(word.lowercased())
    }
}
