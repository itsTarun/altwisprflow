import XCTest
import SwiftUI
@testable import AltWisprFlow

final class FloatingOverlayViewModelTests: XCTestCase {
    private var viewModel = FloatingOverlayViewModel()
    
    override func setUp() {
        super.setUp()
        viewModel = FloatingOverlayViewModel()
    }
    
    func testToggleRecording() {
        XCTAssertFalse(viewModel.isRecording)
        
        viewModel.toggleRecording()
        XCTAssertTrue(viewModel.isRecording)
        
        viewModel.toggleRecording()
        XCTAssertFalse(viewModel.isRecording)
    }
    
    func testTranscriptUpdate() {
        let testTranscript = "This is a test transcript"
        viewModel.transcript = testTranscript
        XCTAssertEqual(viewModel.transcript, testTranscript)
    }
    
    func testConfidenceUpdate() {
        viewModel.confidence = 0.85
        XCTAssertEqual(viewModel.confidence, 0.85)
    }
}
