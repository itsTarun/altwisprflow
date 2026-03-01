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
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        switch status {
        case .authorized:
            return true
        case .denied, .restricted:
            return false
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    continuation.resume(returning: granted)
                }
            }
        @unknown default:
            return false
        }
    }
    
    func startCapture() throws -> Double {
        guard !isCapturing else { return 16000.0 }
        
        // Ensure old engine is cleaned up
        stopCapture()
        
        audioEngine = AVAudioEngine()
        
        guard let audioEngine = audioEngine else {
            throw AudioCaptureError.engineInitializationFailed
        }
        
        let inputNode = audioEngine.inputNode
        let nativeFormat = inputNode.inputFormat(forBus: 0)
        
        if nativeFormat.sampleRate == 0 {
            throw AudioCaptureError.engineInitializationFailed
        }
        
        // AssemblyAI requires 16kHz
        let targetRate = 16000.0
        let targetFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: targetRate, channels: 1, interleaved: false)!
        
        guard let converter = AVAudioConverter(from: nativeFormat, to: targetFormat) else {
            debugLog("[AudioCaptureManager] Failed to create converter")
            throw AudioCaptureError.engineInitializationFailed
        }
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: nativeFormat) { [weak self] buffer, time in
            let ratio = nativeFormat.sampleRate / targetRate
            let capacity = UInt32(Double(buffer.frameLength) / ratio) + 1
            
            guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: capacity) else { return }
            
            var error: NSError?
            let inputBlock: AVAudioConverterInputBlock = { inNumPackets, outStatus in
                outStatus.pointee = .haveData
                return buffer
            }
            
            converter.convert(to: convertedBuffer, error: &error, withInputFrom: inputBlock)
            
            if let error = error {
                debugLog("[AudioCaptureManager] Conversion error: \(error)")
                return
            }
            
            self?.processAudioBuffer(convertedBuffer, time: time)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        isCapturing = true
        debugLog("[AudioCaptureManager] Started capture at \(nativeFormat.sampleRate)Hz, resampled to \(targetRate)Hz")
        return targetRate
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
        var int16Data = [Int16](repeating: 0, count: frameLength)
        
        // Apply some gain (2.0x) to help recognition in quiet environments
        let gain: Float = 2.0
        
        for i in 0..<frameLength {
            let sample = channelData[i] * gain
            let scaled = sample * 32767.0
            let clamped = max(-32768.0, min(32767.0, scaled))
            int16Data[i] = Int16(clamped)
        }
        
        let data = Data(bytes: int16Data, count: frameLength * MemoryLayout<Int16>.size)
        
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
