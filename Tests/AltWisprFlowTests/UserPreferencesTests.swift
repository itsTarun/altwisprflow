import XCTest
@testable import AltWisprFlow

final class UserPreferencesTests: XCTestCase {
    private var preferences = UserPreferences.shared
    
    override func tearDown() {
        preferences = UserPreferences.shared
        super.tearDown()
    }
    
    func testSaveAndLoadAPIKeys() throws {
        preferences.assemblyAIKey = "test_assembly_key"
        preferences.openAIKey = "test_openai_key"
        
        XCTAssertTrue(preferences.validateKeys())
    }
    
    func testEmptyValidation() {
        preferences.assemblyAIKey = ""
        preferences.openAIKey = ""
        
        XCTAssertFalse(preferences.validateKeys())
    }
}
