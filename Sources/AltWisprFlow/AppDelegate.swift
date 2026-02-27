import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    static let shared = AppDelegate()
    
    private var statusItem: NSStatusItem?
    private lazy var audioManager = AudioCaptureManager.shared
    private lazy var transcriptionService = AssemblyAITranscriptionService()
    private lazy var editingService = OpenAIEditingService()
    
    override init() {
        super.init()
        setupAudioSession()
        requestPermissions()
    }
    
    private func setupAudioSession() {
        // TODO: Configure AVAudioSession
    }
    
    private func requestPermissions() {
        // TODO: Request microphone and accessibility permissions
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // TODO: Initialize services
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // TODO: Cleanup
    }
}
