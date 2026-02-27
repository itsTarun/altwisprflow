import XCTest
@testable import AltWisprFlow

final class DictionaryManagerTests: XCTestCase {
    private var manager = DictionaryManager.shared
    
    override func tearDown() {
        manager.removeWord("testword")
        manager.removeWord("anotherword")
        super.tearDown()
    }
    
    func testAddAndRemoveWord() {
        XCTAssertFalse(manager.contains("testword"))
        
        manager.addWord("testword")
        XCTAssertTrue(manager.contains("testword"))
        
        let allWords = manager.getAllWords()
        XCTAssertTrue(allWords.contains("testword"))
        
        manager.removeWord("testword")
        XCTAssertFalse(manager.contains("testword"))
    }
    
    func testPersistenceAcrossInstances() {
        manager.addWord("persistent")
        
        let manager2 = DictionaryManager.shared
        XCTAssertTrue(manager2.contains("persistent"))
        
        manager2.removeWord("persistent")
    }
}
