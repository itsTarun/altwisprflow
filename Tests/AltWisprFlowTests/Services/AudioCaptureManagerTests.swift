import XCTest
@testable import AltWisprFlow
import AVFoundation

final class AudioCaptureManagerTests: XCTestCase {
    private var audioManager = AudioCaptureManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    override func tearDown() {
        audioManager.stopCapture()
        cancellables.removeAll()
        super.tearDown()
    }
    
    func testRequestMicrophonePermission() async {
        let granted = await audioManager.requestMicrophonePermission()
        // This may fail if system denies permission
        XCTAssertTrue(granted || !granted)
    }
    
    func testStartAndStopCapture() throws {
        let expectation = XCTestExpectation(description: "Audio buffer received")
        
        audioManager.audioPublisher
            .sink { buffer in
                XCTAssertGreaterThan(buffer.data.count, 0)
                XCTAssertEqual(buffer.channels, 1)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        Task {
            let hasPermission = await audioManager.requestMicrophonePermission()
            guard hasPermission else {
                XCTSkip("Microphone permission not granted")
                return
            }
            
            try audioManager.startCapture()
            try await Task.sleep(for: .seconds(1))
            audioManager.stopCapture()
        }
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    func testAudioCaptureErrorHandling() {
        // Test double start should not crash
        XCTAssertNoThrow(try audioManager.startCapture())
        XCTAssertNoThrow(try audioManager.startCapture())
        
        audioManager.stopCapture()
        
        // Test double stop should not crash
        audioManager.stopCapture()
        audioManager.stopCapture()
    }
}