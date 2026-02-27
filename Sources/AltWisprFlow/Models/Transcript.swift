import Foundation

struct Transcript: Identifiable, Codable {
    let id = UUID()
    let text: String
    let isFinal: Bool
    let confidence: Double
    let startTime: TimeInterval
    let endTime: TimeInterval
    
    enum CodingKeys: String, CodingKey {
        case text
        case isFinal = "is_final"
        case confidence
        case startTime = "start_time"
        case endTime = "end_time"
    }
}
