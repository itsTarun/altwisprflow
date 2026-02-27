import AVFoundation
import Combine

final class AudioCaptureManager: NSObject {
    static let shared = AudioCaptureManager()
    
    private var audioEngine: AVAudioEngine?
    private var isCapturing = false
    
    private let audioSubject = PassthroughSubject<AudioBuffer, AudioCaptureError>()
    var audioPublisher: AnyPublisher<AudioBuffer, AudioCaptureError> {
        audioSubject.eraseToAnyPublisher()
    }
    
    private override init() {
        super.init()
    }
    
    func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            switch AVAudioSession.sharedInstance().recordPermission {
            case .granted:
                continuation.resume(returning: true)
            case .denied:
                continuation.resume(returning: false)
            case .undetermined:
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            @unknown default:
                continuation.resume(returning: false)
            }
        }
    }
    
    func startCapture() throws {
        guard !isCapturing else { return }
        
        audioEngine = AVAudioEngine()
        
        guard let audioEngine = audioEngine else {
            throw AudioCaptureError.engineInitializationFailed
        }
        
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 2048, format: inputFormat) { [weak self] buffer, time in
            self?.processAudioBuffer(buffer, time: time)
        }
        
        try audioEngine.start()
        isCapturing = true
    }
    
    func stopCapture() {
        guard isCapturing else { return }
        
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        isCapturing = false
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer, time: AVAudioTime) {
        guard let channelData = buffer.floatChannelData?[0] else {
            audioSubject.send(completion: .failure(.engineStartFailure))
            return
        }
        
        let frameLength = Int(buffer.frameLength)
        let data = Data(bytes: channelData, count: frameLength * MemoryLayout<Float>.size)
        
        let audioBuffer = AudioBuffer(
            data: data,
            timestamp: Date(),
            sampleRate: buffer.format.sampleRate,
            channels: Int(buffer.format.channelCount)
        )
        
        audioSubject.send(audioBuffer)
    }
}

enum AudioCaptureError: Error {
    case engineInitializationFailed
    case permissionDenied
    case engineStartFailure
}
