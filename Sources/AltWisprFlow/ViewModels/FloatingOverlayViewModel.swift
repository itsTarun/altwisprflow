import Combine
import AppKit

final class FloatingOverlayViewModel: ObservableObject {
    @Published var transcript: String = ""
    @Published var isRecording: Bool = false
    @Published var confidence: Double = 0.0
    @Published var showPreview: Bool = false
    
    private var audioManager = AudioCaptureManager.shared
    private var transcriptionService = AssemblyAITranscriptionService()
    private var editingService = OpenAIEditingService()
    
    private var cancellables = Set<AnyCancellable>()
    private var isFinalTranscript = false
    
    init() {
        setupBindings()
    }
    
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        isRecording = true
        transcript = ""
        isFinalTranscript = false
        
        Task {
            do {
                try await audioManager.requestMicrophonePermission()
                try audioManager.startCapture()
                try await transcriptionService.connect()
            } catch {
                print("Failed to start recording: \(error)")
                await MainActor.run {
                    self.isRecording = false
                }
            }
        }
    }
    
    private func stopRecording() {
        isRecording = false
        audioManager.stopCapture()
        transcriptionService.disconnect()
        
        if !isFinalTranscript, !transcript.isEmpty {
            Task {
                await self.editAndSend(transcript)
            }
        }
    }
    
    private func setupBindings() {
        audioManager.audioPublisher
            .sink { [weak self] buffer in
                self?.transcriptionService.sendAudioData(buffer.data)
            }
            .store(in: &cancellables)
        
        transcriptionService.transcriptsPublisher
            .sink { [weak self] transcript in
                Task {
                    await self?.handleTranscriptUpdate(transcript)
                }
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    private func handleTranscriptUpdate(_ transcript: Transcript) {
        if transcript.isFinal {
            self.isFinalTranscript = true
            self.transcript = transcript.text
            Task {
                await self.editAndSend(transcript.text)
            }
        } else {
            self.transcript = transcript.text
        }
    }
    
    private func editAndSend(_ text: String) async {
        do {
            let config = UserPreferences.shared.editingConfig
            let edited = try await editingService.editText(text, config: config)
            await MainActor.run {
                self.transcript = edited
                self.copyToClipboardAndPaste()
            }
        } catch {
            print("Editing failed: \(error), using raw text")
            await MainActor.run {
                self.transcript = text
                self.copyToClipboardAndPaste()
            }
        }
    }
    
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    private func pasteToActiveApp() {
        let source = CGEventSource(stateID: .combinedSessionState)
        
        if let keyVDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) {
            keyVDown.flags = .maskCommand
            keyVDown.post(tap: .cgAnnotatedSessionEventTap)
        }
        
        if let keyVUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) {
            keyVUp.flags = .maskCommand
            keyVUp.post(tap: .cgAnnotatedSessionEventTap)
        }
    }
}
