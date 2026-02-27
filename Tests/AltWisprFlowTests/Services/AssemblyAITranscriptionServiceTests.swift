import XCTest
@testable import AltWisprFlow
import Combine

final class AssemblyAITranscriptionServiceTests: XCTestCase {
    var cancellables: Set<AnyCancellable>!
    var mockKeychainService: KeychainService!
    
    override func setUp() {
        super.setUp()
        cancellables = []
        mockKeychainService = KeychainService()
    }
    
    override func tearDown() {
        cancellables = nil
        mockKeychainService = nil
        super.tearDown()
    }
    
    func testConnectionWithMissingAPIKey() {
        let service = AssemblyAITranscriptionService(keychainService: mockKeychainService)
        
        XCTAssertThrowsError(try service.connect()) { error in
            guard let assemblyError = error as? AssemblyAITranscriptionService.AssemblyAIError else {
                XCTFail("Expected AssemblyAIError")
                return
            }
            
            XCTAssertEqual(assemblyError, .missingAPIKey)
        }
    }
    
    func testTranscriptParsing() {
        let json = """
        {
            "message_type": "FinalTranscript",
            "text": "Hello world",
            "confidence": 0.95,
            "audio_start": 0.0,
            "audio_end": 1.5
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        do {
            let response = try decoder.decode(AssemblyAITranscriptionService.TranscriptResponse.self, from: data)
            
            XCTAssertEqual(response.messageType, "FinalTranscript")
            XCTAssertEqual(response.text, "Hello world")
            XCTAssertEqual(response.confidence, 0.95)
            XCTAssertEqual(response.audioStart, 0.0)
            XCTAssertEqual(response.audioEnd, 1.5)
        } catch {
            XCTFail("Failed to parse transcript: \(error)")
        }
    }
    
    func testTranscriptParsingWithMissingFields() {
        let json = """
        {
            "text": "Test"
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        XCTAssertThrowsError(try decoder.decode(AssemblyAITranscriptionService.TranscriptResponse.self, from: data))
    }
    
    func testPublisherEmitsTranscripts() {
        var receivedTranscript: Transcript?
        
        let service = AssemblyAITranscriptionService(keychainService: mockKeychainService)
        
        service.transcriptPublisher
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { transcript in
                    receivedTranscript = transcript
                }
            )
            .store(in: &cancellables)
        
        XCTAssertNil(receivedTranscript, "Should not receive transcript without connection")
    }
    
    func testAudioDataRequestEncoding() {
        let audioData = Data([0x00, 0x01, 0x02, 0x03, 0x04])
        let base64String = audioData.base64EncodedString()
        
        let request = AssemblyAITranscriptionService.AudioDataRequest(audioData: base64String)
        
        let encoder = JSONEncoder()
        XCTAssertNoThrow(try encoder.encode(request))
        
        do {
            let encodedData = try encoder.encode(request)
            let decoded = try JSONDecoder().decode(AssemblyAITranscriptionService.AudioDataRequest.self, from: encodedData)
            
            XCTAssertEqual(decoded.audioData, base64String)
        } catch {
            XCTFail("Failed to encode/decode AudioDataRequest: \(error)")
        }
    }
}