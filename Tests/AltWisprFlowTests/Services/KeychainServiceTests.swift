import XCTest
@testable import AltWisprFlow

final class KeychainServiceTests: XCTestCase {
    private var service = KeychainService()
    
    override func tearDown() {
        try? service.deleteAPIKeys()
        super.tearDown()
    }
    
    func testSaveAndLoadAPIKeys() throws {
        let keys = APIKeys(assemblyAI: "test_assembly", openAI: "test_openai")
        try service.saveAPIKeys(keys)
        
        let loaded = service.loadAPIKeys()
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.assemblyAI, "test_assembly")
        XCTAssertEqual(loaded?.openAI, "test_openai")
    }
    
    func testHasAPIKeys() throws {
        XCTAssertFalse(service.hasAPIKeys())
        
        let keys = APIKeys(assemblyAI: "test", openAI: "test")
        try service.saveAPIKeys(keys)
        
        XCTAssertTrue(service.hasAPIKeys())
    }
    
    func testDeleteAPIKeys() throws {
        let keys = APIKeys(assemblyAI: "test", openAI: "test")
        try service.saveAPIKeys(keys)
        
        try service.deleteAPIKeys()
        
        XCTAssertNil(service.loadAPIKeys())
        XCTAssertFalse(service.hasAPIKeys())
    }
}
