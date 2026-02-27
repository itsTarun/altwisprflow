import Foundation
import OpenAI

final class OpenAIEditingService {
    private var client: OpenAI?
    
    init() {
        setupClient()
    }
    
    private func setupClient() {
        guard let apiKeys = KeychainService().loadAPIKeys(),
              !apiKeys.openAI.isEmpty else {
            print("OpenAI API key not configured")
            return
        }
        
        let configuration = OpenAI.Configuration(
            token: apiKeys.openAI,
            timeoutInterval: 60.0
        )
        self.client = OpenAI(configuration: configuration)
    }
    
    func editText(_ text: String, config: EditingConfig = .default) async throws -> String {
        guard let client = client else {
            throw EditingError.missingAPIKey
        }
        
        let prompt = buildEditingPrompt(text: text, config: config)
        
        let query = ChatQuery(
            messages: [.init(role: .system, content: prompt.system!), .init(role: .user, content: prompt.user)],
            model: .gpt4_o_mini,
            maxTokens: config.maxTokens,
            temperature: config.temperature
        )
        
        let result = try await client.chats(query: query)
        
        guard let editedText = result.choices.first?.message.content?.string else {
            throw EditingError.emptyResponse
        }
        
        return editedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func buildEditingPrompt(text: String, config: EditingConfig) -> (system: String?, user: String) {
        var instructions: [String] = []
        
        if config.removeFillerWords {
            instructions.append("- Remove filler words like 'um', 'uh', 'like', 'you know'")
        }
        
        if config.correctGrammar {
            instructions.append("- Fix grammar and punctuation errors")
        }
        
        if config.matchTone {
            instructions.append("- Match the appropriate tone for the context")
        }
        
        instructions.append("- Make only necessary changes, preserve the original meaning")
        instructions.append("- Return only the edited text without explanations")
        
        let system = """
        You are a professional text editor. Your task is to clean up transcribed speech.
        
        Rules:
        \(instructions.joined(separator: "\n"))
        """
        
        return (system, text)
    }
}

enum EditingError: Error {
    case missingAPIKey
    case emptyResponse
}
