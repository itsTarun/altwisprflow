import GRDB

final class SnippetManager {
    static let shared = SnippetManager()
    
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
            let dbURL = appSupport.appendingPathComponent("snippets.sqlite")
            
            database = try DatabaseQueue(path: dbURL.path)
            
            try database?.write { db in
                try db.create(table: "snippets", ifNotExists: true) { t in
                    t.column("id", .text).primaryKey()
                    t.column("name", .text).notNull()
                    t.column("text", .text).notNull()
                    t.column("keywords", .text)
                    t.column("created_at", .datetime).defaults(sql: "CURRENT_TIMESTAMP")
                }
            }
        } catch {
            print("Failed to setup snippets database: \(error)")
        }
    }
    
    func createSnippet(name: String, text: String, keywords: [String]) throws -> Snippet {
        let snippet = Snippet(name: name, text: text, keywords: keywords)
        
        try database?.write { db in
            try db.execute(
                sql: "INSERT INTO snippets (id, name, text, keywords) VALUES (?, ?, ?, ?)",
                arguments: [
                    snippet.id.uuidString,
                    snippet.name,
                    snippet.text,
                    snippet.keywords.joined(separator: ",")
                ]
            )
        }
        
        return snippet
    }
    
    func getAllSnippets() throws -> [Snippet] {
        guard let database = database else { return [] }
        
        return try database.read { db in
            try Row
                .fetchAll(db, sql: "SELECT id, name, text, keywords FROM snippets ORDER BY created_at DESC")
                .map { row in
                    Snippet(
                        id: UUID(uuidString: row["id"]!) ?? UUID(),
                        name: row["name"] ?? "",
                        text: row["text"] ?? "",
                        keywords: (row["keywords"] as? String)?.split(separator: ",").map(String.init) ?? []
                    )
                }
        }
    }
    
    func findSnippets(byKeyword keyword: String) throws -> [Snippet] {
        let allSnippets = try getAllSnippets()
        return allSnippets.filter { snippet in
            snippet.keywords.contains { $0.lowercased().contains(keyword.lowercased()) }
        }
    }
    
    func deleteSnippet(id: UUID) throws {
        try database?.write { db in
            try db.execute(
                sql: "DELETE FROM snippets WHERE id = ?",
                arguments: [id.uuidString]
            )
        }
    }
}
