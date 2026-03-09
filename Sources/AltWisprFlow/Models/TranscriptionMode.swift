import Foundation

public enum TranscriptionMode: String, CaseIterable, Identifiable {
    case cloud = "AssemblyAI (Cloud)"
    case local = "MLX (Local - Offline)"
    
    public var id: String { self.rawValue }
}
