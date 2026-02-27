import Foundation
import Combine

final class AssemblyAITranscriptionService: ObservableObject {
    private let keychainService: KeychainService
    private var webSocketTask: URLSessionWebSocketTask?
    private let session = URLSession(configuration: .default)
    
    private let transcriptSubject = PassthroughSubject<Transcript, Error>()
    var transcriptPublisher: AnyPublisher<Transcript, Error> {
        transcriptSubject.eraseToAnyPublisher()
    }
    
    init(keychainService: KeychainService = KeychainService()) {
        self.keychainService = keychainService
    }
    
    func connect() throws {
        guard let apiKeys = keychainService.loadAPIKeys() else {
            throw AssemblyAIError.missingAPIKey
        }
        
        guard !apiKeys.assemblyAI.isEmpty else {
            throw AssemblyAIError.missingAPIKey
        }
        
        var urlComponents = URLComponents(string: "wss://api.assemblyai.com/v2/stream")!
        urlComponents.queryItems = [URLQueryItem(name: "sample_rate", value: "16000")]
        
        guard let url = urlComponents.url else {
            throw AssemblyAIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue(apiKeys.assemblyAI, forHTTPHeaderField: "Authorization")
        
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()
        
        receiveMessage()
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self?.handleMessage(text)
                    }
                @unknown default:
                    break
                }
                self?.receiveMessage()
                
            case .failure(let error):
                self?.transcriptSubject.send(completion: .failure(error))
            }
        }
    }
    
    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        
        if let response = try? JSONDecoder().decode(TranscriptResponse.self, from: data) {
            if response.messageType == "FinalTranscript" || response.messageType == "PartialTranscript" {
                let transcript = Transcript(
                    text: response.text,
                    isFinal: response.messageType == "FinalTranscript",
                    confidence: response.confidence ?? 0.0,
                    startTime: response.audioStart ?? 0.0,
                    endTime: response.audioEnd ?? 0.0
                )
                transcriptSubject.send(transcript)
            }
        } else if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
            transcriptSubject.send(completion: .failure(AssemblyAIError.apiError(errorResponse.error)))
        }
    }
    
    func sendAudioData(_ data: Data) {
        guard webSocketTask?.state == .running else { return }
        
        let base64String = data.base64EncodedString()
        let audioMessage = AudioDataRequest(audioData: base64String)
        
        guard let jsonData = try? JSONEncoder().encode(audioMessage),
              let jsonString = String(data: jsonData, encoding: .utf8) else { return }
        
        let message = URLSessionWebSocketTask.Message.string(jsonString)
        webSocketTask?.send(message) { error in
            if let error = error {
                self.transcriptSubject.send(completion: .failure(error))
            }
        }
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }
    
    deinit {
        disconnect()
    }
}

extension AssemblyAITranscriptionService {
    enum AssemblyAIError: LocalizedError {
        case missingAPIKey
        case invalidURL
        case apiError(String)
        
        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "AssemblyAI API key not found in keychain"
            case .invalidURL:
                return "Invalid WebSocket URL"
            case .apiError(let message):
                return "AssemblyAI API error: \(message)"
            }
        }
    }
    
    struct TranscriptResponse: Codable {
        let messageType: String
        let text: String
        let confidence: Double?
        let audioStart: TimeInterval?
        let audioEnd: TimeInterval?
        
        enum CodingKeys: String, CodingKey {
            case messageType = "message_type"
            case text
            case confidence
            case audioStart = "audio_start"
            case audioEnd = "audio_end"
        }
    }
    
    struct ErrorResponse: Codable {
        let error: String
    }
    
    struct AudioDataRequest: Codable {
        let audioData: String
        
        enum CodingKeys: String, CodingKey {
            case audioData = "audio_data"
        }
    }
}
