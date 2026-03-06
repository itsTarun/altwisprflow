import Foundation
import Combine

protocol TranscriptionProvider: AnyObject {
    var transcriptPublisher: AnyPublisher<Transcript, Error> { get }
    var isSessionBegun: Bool { get }
    
    func connect(sampleRate: Int) throws
    func sendAudioData(_ data: Data)
    func disconnect()
}
