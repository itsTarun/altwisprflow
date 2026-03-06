import Foundation
import Combine
import MLX
import MLXAudioCore
// import MLXAudioSTT // Missing WhisperModel?

final class LocalMLXProvider: TranscriptionProvider {
    private let transcriptSubject = PassthroughSubject<Transcript, Error>()
    var transcriptPublisher: AnyPublisher<Transcript, Error> {
        transcriptSubject.eraseToAnyPublisher()
    }
    
    var isSessionBegun: Bool = false
    private var isConnected: Bool = false
    private let sampleRate = 16000
    
    private var audioBuffer: [Float] = []
    private let bufferLock = NSLock()
    
    private var inferenceTask: Task<Void, Never>?
    
    func connect(sampleRate: Int) throws {
        isConnected = true
        isSessionBegun = true
        
        let repoId = "mlx-community/whisper-tiny-mlx-4bit"
        
        Task {
            do {
                if !ModelDownloader.shared.isModelDownloaded(repoId: repoId) {
                    try await ModelDownloader.shared.downloadModel(repoId: repoId)
                }
                
                let modelDir = ModelDownloader.shared.modelsDirectory(for: repoId)
                
                // TODO: Load MLX Whisper model here
                // let model = try await WhisperModel.fromPretrained(modelDir.path)
                
                startInferenceLoop()
            } catch {
                transcriptSubject.send(completion: .failure(error))
                disconnect()
            }
        }
    }
    
    func sendAudioData(_ data: Data) {
        guard isConnected else { return }
        
        // Convert PCM 16-bit Int16 to Float
        let count = data.count / MemoryLayout<Int16>.size
        var pcm = [Int16](repeating: 0, count: count)
        _ = pcm.withUnsafeMutableBytes { data.copyBytes(to: $0) }
        
        let floats = pcm.map { Float($0) / 32768.0 }
        
        bufferLock.lock()
        audioBuffer.append(contentsOf: floats)
        bufferLock.unlock()
    }
    
    func disconnect() {
        isConnected = false
        isSessionBegun = false
        inferenceTask?.cancel()
        inferenceTask = nil
        bufferLock.lock()
        audioBuffer.removeAll()
        bufferLock.unlock()
    }
    
    private func startInferenceLoop() {
        inferenceTask = Task {
            while !Task.isCancelled && isConnected {
                bufferLock.lock()
                // Wait for ~1 second of audio (16000 samples)
                if audioBuffer.count >= sampleRate {
                    let samplesToProcess = audioBuffer
                    audioBuffer.removeAll()
                    bufferLock.unlock()
                    
                    // TODO: Run inference
                    // let audioArray = MLXArray(samplesToProcess)
                    // let result = model.generate(audio: audioArray)
                    
                    let transcript = Transcript(
                        text: "[Mock Transcription for \(samplesToProcess.count) samples]",
                        isFinal: true,
                        confidence: 1.0,
                        startTime: Date().timeIntervalSince1970,
                        endTime: Date().timeIntervalSince1970 + 1.0
                    )
                    
                    self.transcriptSubject.send(transcript)
                } else {
                    bufferLock.unlock()
                    try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                }
            }
        }
    }
}
