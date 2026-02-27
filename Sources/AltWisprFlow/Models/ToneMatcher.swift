import Foundation

struct ToneMatcher {
    func getToneForApp(bundleIdentifier: String) -> String {
        switch bundleIdentifier {
        case "com.apple.Mail", "com.microsoft.Outlook":
            return "professional email"
        case "com.slack.Slack", "com.microsoft.Teams":
            return "casual chat"
        case "com.microsoft.Word", "com.apple.Pages":
            return "formal document"
        case "com.apple.Messages":
            return "casual message"
        default:
            return "neutral"
        }
    }
    
    func buildTonePrompt(tone: String, text: String) -> String {
        return """
        Clean up this text for a \(tone):
        \n        \(text)
        \n        Keep the same meaning but adjust the tone appropriately.
        Return only the edited text.
        """
    }
}
