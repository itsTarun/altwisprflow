import XCTest
@testable import AltWisprFlow

final class SnippetManagerTests: XCTestCase {
    private var manager = SnippetManager.shared
    
    override func setUp() {
        super.setUp()
        try? manager.getAllSnippets().forEach { snippet in
            try? manager.deleteSnippet(id: snippet.id)
        }
    }
    
    func testCreateAndRetrieveSnippet() throws {
        let snippet = try manager.createSnippet(
            name: "Test Snippet",
            text: "This is a test snippet",
            keywords: ["test", "demo"]
        )
        
        XCTAssertEqual(snippet.name, "Test Snippet")
        XCTAssertEqual(snippet.text, "This is a test snippet")
        XCTAssertTrue(snippet.keywords.contains("test"))
        XCTAssertTrue(snippet.keywords.contains("demo"))
    }
    
    func testFindSnippetsByKeyword() throws {
        try manager.createSnippet(
            name: "Meeting Snippet",
            text: "Let's schedule a meeting",
            keywords: ["meeting", "schedule"]
        )
        
        try manager.createSnippet(
            name: "Calendar Snippet",
            text: "Please check the calendar",
            keywords: ["calendar", "schedule"]
        )
        
        let found = try manager.findSnippets(byKeyword: "schedule")
        XCTAssertEqual(found.count, 2)
        
        let meetingFound = try manager.findSnippets(byKeyword: "meeting")
        XCTAssertEqual(meetingFound.count, 1)
        XCTAssertEqual(meetingFound.first?.name, "Meeting Snippet")
    }
    
    func testDeleteSnippet() throws {
        let snippet = try manager.createSnippet(
            name: "To Delete",
            text: "This will be deleted",
            keywords: []
        )
        
        try manager.deleteSnippet(id: snippet.id)
        
        let all = try manager.getAllSnippets()
        XCTAssertFalse(all.contains(where: { $0.id == snippet.id }))
    }
}
