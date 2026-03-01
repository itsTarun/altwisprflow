import Foundation
import GRDB

final class DictionaryManager {
    static let shared = DictionaryManager()
    
    private var database: DatabaseQueue?
    private var cachedDictionary: PersonalDictionary?
    
    private init() {
        setupDatabase()
    }
    
    private func setupDatabase() {
        do {
            let fileManager = FileManager.default
            let appSupport = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let dbURL = appSupport.appendingPathComponent("dictionary.sqlite")
            
            database = try DatabaseQueue(path: dbURL.path)
            
            try database?.write { db in
                try db.create(table: "dictionary", ifNotExists: true) { t in
                    t.column("word", .text).primaryKey()
                    t.column("added_at", .datetime).defaults(sql: "CURRENT_TIMESTAMP")
                }
            }
        } catch {
            debugLog("Failed to setup database: \(error)")
        }
    }
    
    func loadDictionary() -> PersonalDictionary {
        if let cached = cachedDictionary {
            return cached
        }
        
        var words = Set<String>()
        
        do {
            try database?.read { db in
                let rows = try Row.fetchCursor(db, sql: "SELECT word FROM dictionary")
                while let row = try rows.next() {
                    if let word: String = row["word"] {
                        words.insert(word)
                    }
                }
            }
        } catch {
            debugLog("Failed to load dictionary: \(error)")
        }
        
        let dictionary = PersonalDictionary(words: words)
        cachedDictionary = dictionary
        return dictionary
    }
    
    func saveDictionary(_ dictionary: PersonalDictionary) {
        cachedDictionary = dictionary
        
        do {
            try database?.write { db in
                try db.execute(sql: "DELETE FROM dictionary")
                
                for word in dictionary.words {
                    try db.execute(
                        sql: "INSERT INTO dictionary (word) VALUES (?)",
                        arguments: [word]
                    )
                }
            }
        } catch {
            debugLog("Failed to save dictionary: \(error)")
        }
    }
    
    func addWord(_ word: String) {
        var dictionary = loadDictionary()
        dictionary.addWord(word)
        saveDictionary(dictionary)
    }
    
    func removeWord(_ word: String) {
        var dictionary = loadDictionary()
        dictionary.removeWord(word)
        saveDictionary(dictionary)
    }
    
    func contains(_ word: String) -> Bool {
        return loadDictionary().contains(word)
    }
    
    func getAllWords() -> [String] {
        return Array(loadDictionary().words).sorted()
    }
}
