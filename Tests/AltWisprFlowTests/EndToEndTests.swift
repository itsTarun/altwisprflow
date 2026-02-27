import XCTest
@testable import AltWisprFlow
import Combine

final class EndToEndTests: XCTestCase {
    func testToneMatching() {
        let toneMatcher = ToneMatcher()
        
        XCTAssertEqual(toneMatcher.getToneForApp(bundleIdentifier: "com.apple.Mail"), "professional email")
        XCTAssertEqual(toneMatcher.getToneForApp(bundleIdentifier: "com.slack.Slack"), "casual chat")
        XCTAssertEqual(toneMatcher.getToneForApp(bundleIdentifier: "com.microsoft.Word"), "formal document")
        XCTAssertEqual(toneMatcher.getToneForApp(bundleIdentifier: "com.apple.Messages"), "casual message")
        XCTAssertEqual(toneMatcher.getToneForApp(bundleIdentifier: "unknown"), "neutral")
    }
    
    func testEndToEndDictation() async {
        let audioManager = AudioCaptureManager.shared
        let transcription = AssemblyAITranscriptionService()
        let editing = OpenAIEditingService()
        
        guard await audioManager.requestMicrophonePermission() else {
            XCTSkip("Microphone permission required")
            return
        }
        
        guard KeychainService().hasAPIKeys() else {
            XCTSkip("API keys required")
            return
        }
        
        var error: Error?
        
        do {
            try await transcription.connect()
            try audioManager.startCapture()
            try await Task.sleep(for: .seconds(1))
            audioManager.stopCapture()
            transcription.disconnect()
        } catch {
            error = error
        }
        
        XCTAssertNil(error, "Pipeline should run without errors")
    }
}
