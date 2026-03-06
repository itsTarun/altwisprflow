import Foundation
import Combine

final class AssemblyAITranscriptionService: ObservableObject, TranscriptionProvider {
    private let keychainService: KeychainService
    private var webSocketTask: URLSessionWebSocketTask?
    private let session = URLSession(configuration: .default)
    private var sessionBegun = false
    private let sessionLock = NSLock()
    
    private let transcriptSubject = PassthroughSubject<Transcript, Error>()
    var transcriptPublisher: AnyPublisher<Transcript, Error> {
        transcriptSubject.eraseToAnyPublisher()
    }
    
    var isSessionBegun: Bool {
        sessionLock.lock()
        defer { sessionLock.unlock() }
        return sessionBegun
    }
    
    init(keychainService: KeychainService = KeychainService()) {
        self.keychainService = keychainService
    }
    
    func connect(sampleRate: Int = 16000) throws {
        // Always disconnect existing task first
        disconnect()
        
        sessionLock.lock()
        sessionBegun = false
        sessionLock.unlock()
        
        guard let apiKeys = keychainService.loadAPIKeys() else {
            debugLog("Missing API Keys for AssemblyAI")
            throw AssemblyAIError.missingAPIKey
        }
        
        guard !apiKeys.assemblyAI.isEmpty else {
            debugLog("Empty AssemblyAI Key")
            throw AssemblyAIError.missingAPIKey
        }
        
        // AssemblyAI Streaming API v3 - Universal Streaming
        // Endpoint: wss://streaming.assemblyai.com/v3/ws
        var urlComponents = URLComponents()
        urlComponents.scheme = "wss"
        urlComponents.host = "streaming.assemblyai.com"
        urlComponents.path = "/v3/ws"
        urlComponents.queryItems = [
            URLQueryItem(name: "sample_rate", value: String(sampleRate)),
            URLQueryItem(name: "encoding", value: "pcm_s16le")
        ]
        
        guard let url = urlComponents.url else {
            throw AssemblyAIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue(apiKeys.assemblyAI, forHTTPHeaderField: "Authorization")
        
        debugLog("Connecting to AssemblyAI Streaming API v3: \(url)")
        let task = session.webSocketTask(with: request)
        self.webSocketTask = task
        task.resume()
        
        receiveMessage(for: task)
    }
    
    private func receiveMessage(for task: URLSessionWebSocketTask) {
        task.receive { [weak self] result in
            guard let self = self else { return }
            
            // Only continue if this is still the active task
            guard task === self.webSocketTask else {
                return
            }
            
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.handleMessage(text)
                    }
                @unknown default:
                    break
                }
                self.receiveMessage(for: task)
                
            case .failure(let error):
                let nsError = error as NSError
                if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                    debugLog("AssemblyAI: WebSocket task cancelled")
                } else {
                    debugLog("AssemblyAI WebSocket Error: \(error)")
                    self.transcriptSubject.send(completion: .failure(error))
                }
            }
        }
    }
    
    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let messageType = json["type"] as? String else {
            return
        }
        
        switch messageType {
        case "Begin":
            sessionLock.lock()
            self.sessionBegun = true
            sessionLock.unlock()
            if let sessionId = json["id"] as? String {
                debugLog("AssemblyAI Session Started: \(sessionId)")
            }
            
        case "Turn":
            // Turn message contains final or partial transcript
            let transcriptText = json["transcript"] as? String ?? ""
            let endOfTurn = json["end_of_turn"] as? Bool ?? false
            
            if !transcriptText.isEmpty {
                let isFinal = endOfTurn
                
                let transcript = Transcript(
                    text: transcriptText,
                    isFinal: isFinal,
                    confidence: json["confidence"] as? Double ?? 0.0,
                    startTime: json["audio_start"] as? TimeInterval ?? 0.0,
                    endTime: json["audio_end"] as? TimeInterval ?? 0.0
                )
                transcriptSubject.send(transcript)
            }
            
        case "Termination":
            let audioDuration = json["audio_duration_seconds"] as? Double ?? 0
            debugLog("Session Terminated - Audio: \(audioDuration)s")
            
        case "error":
            if let error = json["error"] as? String {
                debugLog("AssemblyAI API Error: \(error)")
                transcriptSubject.send(completion: .failure(AssemblyAIError.apiError(error)))
            }
            
        default:
            break
        }
    }
    
    func sendAudioData(_ data: Data) {
        guard isSessionBegun else {
            return
        }
        
        // AssemblyAI v3 expects RAW BINARY PCM audio
        let message = URLSessionWebSocketTask.Message.data(data)
        webSocketTask?.send(message) { [weak self] error in
            if let error = error {
                debugLog("Error sending audio data: \(error)")
                self?.transcriptSubject.send(completion: .failure(error))
            }
        }
    }
    
    func disconnect() {
        sessionLock.lock()
        sessionBegun = false
        sessionLock.unlock()
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
}
