import Foundation
import GRDB

struct HistoryItem: Codable, FetchableRecord, PersistableRecord {
    var id: UUID
    var text: String
    var createdAt: Date
    
    static let databaseTableName = "history"
}

final class HistoryManager {
    static let shared = HistoryManager()
    
    private var database: DatabaseQueue?
    
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
            let dbURL = appSupport.appendingPathComponent("history.sqlite")
            
            database = try DatabaseQueue(path: dbURL.path)
            
            try database?.write { db in
                try db.create(table: "history", ifNotExists: true) { t in
                    t.column("id", .text).primaryKey()
                    t.column("text", .text).notNull()
                    t.column("createdAt", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
                }
            }
        } catch {
            debugLog("[HistoryManager] Failed to setup database: \(error)")
        }
    }
    
    func save(_ text: String) {
        let item = HistoryItem(id: UUID(), text: text, createdAt: Date())
        do {
            try database?.write { db in
                try item.insert(db)
            }
            debugLog("[HistoryManager] Saved item to history")
        } catch {
            debugLog("[HistoryManager] Failed to save item: \(error)")
        }
    }
    
    func getAll() -> [HistoryItem] {
        do {
            return try database?.read { db in
                try HistoryItem.order(Column("createdAt").desc).fetchAll(db)
            } ?? []
        } catch {
            debugLog("[HistoryManager] Failed to fetch history: \(error)")
            return []
        }
    }
    
    func clear() {
        do {
            _ = try database?.write { db in
                try HistoryItem.deleteAll(db)
            }
        } catch {
            debugLog("[HistoryManager] Failed to clear history: \(error)")
        }
    }
}
