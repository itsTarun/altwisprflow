import Cocoa

func debugLog(_ message: String) {
    let text = "[\(Date())] \(message)\n"
    if let fileHandle = try? FileHandle(forWritingTo: URL(fileURLWithPath: "/tmp/altwispr_debug.log")) {
        fileHandle.seekToEndOfFile()
        fileHandle.write(text.data(using: .utf8)!)
        try? fileHandle.close()
    } else {
        try? text.write(toFile: "/tmp/altwispr_debug.log", atomically: true, encoding: .utf8)
    }
    print(message)
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    static let shared = AppDelegate()
    
    private var statusItem: NSStatusItem?
    private lazy var audioManager = AudioCaptureManager.shared
    private lazy var transcriptionService = AssemblyAITranscriptionService()
    private lazy var editingService = OpenAIEditingService()
    
    override init() {
        super.init()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        debugLog("[AltWisprFlow] App launched")
        _ = HotkeyManager.shared
        debugLog("[AltWisprFlow] HotkeyManager initialized. Press Control+Option+Space to activate dictation.")
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        audioManager.stopCapture()
    }
}
