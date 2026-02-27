import XCTest
@testable import AltWisprFlow

final class OpenAIEditingServiceTests: XCTestCase {
    private var service: OpenAIEditingService!
    
    override func setUp() {
        super.setUp()
        service = OpenAIEditingService()
    }
    
    func testEditTextRemovesFillerWords() async throws {
        let input = "Um, I think like, you know, we should probably, uh, do it this way."
        let result = try await service.editText(input)
        
        XCTAssertFalse(result.contains("Um"))
        XCTAssertFalse(result.contains("like"))
        XCTAssertFalse(result.contains("you know"))
        XCTAssertFalse(result.contains("uh"))
    }
    
    func testEditTextCorrectsGrammar() async throws {
        let input = "he go to the store yesterday and buyed some milk"
        let result = try await service.editText(input)
        
        XCTAssertTrue(result.contains("went") || result.contains("went to"))
        XCTAssertTrue(result.contains("bought"))
    }
    
    func testEditTextWithDefaultConfig() async throws {
        let input = "I think we should implement this feature because it's important for users"
        let result = try await service.editText(input)
        
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("implement") || result.contains("add"))
    }
    
    func testEmptyInput() async throws {
        let input = ""
        let result = try await service.editText(input)
        
        XCTAssertTrue(result.isEmpty)
    }
}
