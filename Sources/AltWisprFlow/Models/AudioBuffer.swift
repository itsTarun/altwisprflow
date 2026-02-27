import Foundation

struct AudioBuffer {
    let data: Data
    let timestamp: Date
    let sampleRate: Double
    let channels: Int
    
    init(data: Data, timestamp: Date = Date(), sampleRate: Double, channels: Int) {
        self.data = data
        self.timestamp = timestamp
        self.sampleRate = sampleRate
        self.channels = channels
    }
}