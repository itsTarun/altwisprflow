import Combine
import AppKit
import SwiftUI

final class FloatingOverlayViewModel: ObservableObject {
    static let shared = FloatingOverlayViewModel()
    
    @Published var transcript: String = ""
    @Published var isRecording: Bool = false
    @Published var confidence: Double = 0.0
    @Published var showPreview: Bool = false
    @Published var history: [String] = []
    @Published var statusMessage: String = "Ready"
    @Published var isLatched: Bool = false
    
    private var audioManager = AudioCaptureManager.shared
    private var transcriptionService: TranscriptionProvider = AssemblyAITranscriptionService()
    private var editingService = OpenAIEditingService()
    private var historyManager = HistoryManager.shared
    
    @AppStorage("transcriptionMode") private var transcriptionMode: TranscriptionMode = .cloud
    private var transcriptionCancellable: AnyCancellable?
    
    private var cancellables = Set<AnyCancellable>()
    private var isFinalTranscript = false
    private var startTask: Task<Void, Never>?
    
    init() {
        setupBindings()
        loadHistory()
    }
    
    private func loadHistory() {
        self.history = historyManager.getAll().map { $0.text }
    }
    
    func clearHistory() {
        historyManager.clear()
        self.history = []
    }
    
    private var isStarting = false
    
    func toggleRecording() {
        debugLog("[FloatingOverlayViewModel] toggleRecording called. isRecording: \(isRecording), isStarting: \(isStarting)")
        if isRecording {
            isLatched = false
            stopRecording()
        } else {
            if !isStarting {
                startRecording()
            } else {
                debugLog("[FloatingOverlayViewModel] Already starting, ignoring toggle")
            }
        }
    }
    
    private func startRecording() {
        if isStarting { return }
        isStarting = true
        
        startTask?.cancel()
        
        // 1. Check keys FIRST
        let currentMode = transcriptionMode
        if currentMode == .cloud {
            guard KeychainService().hasAPIKeys() else {
                debugLog("[FloatingOverlayViewModel] Cannot start: Missing API keys in Keychain")
                isStarting = false
                self.transcript = "Error: Please set API keys in Settings"
                self.statusMessage = "Error: Missing API Keys"
                FloatingOverlayWindow.shared.show()
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    FloatingOverlayWindow.shared.hide()
                }
                return
            }
        }
        
        isRecording = true
        transcript = "Listening..."
        statusMessage = "Connecting..."
        isFinalTranscript = false
        
        startTask = Task {
            do {
                let granted = await audioManager.requestMicrophonePermission()
                if Task.isCancelled { 
                    isStarting = false
                    return 
                }
                
                if !granted {
                    debugLog("[FloatingOverlayViewModel] Microphone permission denied")
                    await MainActor.run { 
                        self.isStarting = false
                        self.isRecording = false
                        self.transcript = "Error: Mic permission denied"
                        self.statusMessage = "Error: Mic Permission Denied"
                    }
                    return
                }
                
                // Connect to WebSocket FIRST
                do {
                    if currentMode == .local {
                        // self.transcriptionService = LocalMLXProvider()
                        // Temporarily bypass LocalMLXProvider to allow compilation
                        self.transcriptionService = AssemblyAITranscriptionService()
                    } else {
                        self.transcriptionService = AssemblyAITranscriptionService()
                    }
                    setupTranscriptionBinding()
                    
                    try transcriptionService.connect(sampleRate: 16000)
                    await MainActor.run {
                        self.statusMessage = "Connecting..."
                    }
                } catch {
                    isStarting = false
                    throw error
                }
                
                // Wait for session to begin before starting audio capture
                debugLog("[FloatingOverlayViewModel] Waiting for session to begin...")
                var waitCount = 0
                while !transcriptionService.isSessionBegun && waitCount < 50 {
                    try await Task.sleep(nanoseconds: 100_000_000) // 100ms
                    waitCount += 1
                    if Task.isCancelled { 
                        isStarting = false
                        return 
                    }
                }
                
                if Task.isCancelled { 
                    isStarting = false
                    return 
                }
                
                if !transcriptionService.isSessionBegun {
                    debugLog("[FloatingOverlayViewModel] Session failed to begin in time")
                    transcriptionService.disconnect()
                    await MainActor.run {
                        self.isStarting = false
                        self.isRecording = false
                        self.transcript = "Error: Connection timeout"
                        self.statusMessage = "Error: Connection Timeout"
                    }
                    return
                }
                
                debugLog("[FloatingOverlayViewModel] Session begun, starting audio capture...")
                isStarting = false
                
                // Now start audio capture
                _ = try audioManager.startCapture()
                
                await MainActor.run {
                    self.statusMessage = "Listening..."
                }
            } catch {
                debugLog("[FloatingOverlayViewModel] Failed to start: \(error)")
                await MainActor.run {
                    self.isStarting = false
                    self.isRecording = false
                    self.transcript = "Error: \(error.localizedDescription)"
                    self.statusMessage = "Error: \(error.localizedDescription)"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        if !self.isRecording {
                            FloatingOverlayWindow.shared.hide()
                        }
                    }
                }
            }
        }
    }
    
    private func stopRecording() {
        startTask?.cancel()
        
        isRecording = false
        audioManager.stopCapture()
        transcriptionService.disconnect()
        
        if !isFinalTranscript, !transcript.isEmpty, transcript != "Listening..." {
            if !UserPreferences.shared.openAIKey.isEmpty {
                transcript = "Polishing text..."
                Task {
                    await self.editAndSend(transcript)
                }
            } else {
                debugLog("[FloatingOverlayViewModel] OpenAI key missing, skipping polish")
                self.copyToClipboard(transcript)
                self.pasteToActiveApp()
            }
        } else if isFinalTranscript && UserPreferences.shared.openAIKey.isEmpty {
             // If it was already final and no OpenAI, it should have been pasted
             // but let's be safe
             FloatingOverlayWindow.shared.hide()
        } else {
            FloatingOverlayWindow.shared.hide()
        }
    }
    
    private func setupBindings() {
        audioManager.audioPublisher
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    debugLog("Audio capture error: \(error)")
                }
            }, receiveValue: { [weak self] buffer in
                self?.transcriptionService.sendAudioData(buffer.data)
            })
            .store(in: &cancellables)
        
        setupTranscriptionBinding()
            
        HotkeyManager.shared.activatedPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] action in
                debugLog("[FloatingOverlayViewModel] Received hotkey activation event: \(action)")
                switch action {
                case .start:
                    self?.startRecording()
                case .stop:
                    self?.isLatched = false
                    self?.stopRecording()
                case .latched:
                    self?.isLatched = true
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupTranscriptionBinding() {
        transcriptionCancellable?.cancel()
        
        transcriptionCancellable = transcriptionService.transcriptPublisher
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    debugLog("Transcription error: \(error)")
                    DispatchQueue.main.async {
                        self?.statusMessage = "Error: \(error.localizedDescription)"
                    }
                }
            }, receiveValue: { [weak self] transcript in
                Task {
                    await self?.handleTranscriptUpdate(transcript)
                }
            })
    }
    
    @MainActor
    private func handleTranscriptUpdate(_ transcript: Transcript) {
        if transcript.isFinal {
            self.isFinalTranscript = true
            self.transcript = transcript.text
            self.statusMessage = "Transcription Complete"
            if !UserPreferences.shared.openAIKey.isEmpty {
                Task {
                    self.statusMessage = "Polishing text..."
                    await self.editAndSend(transcript.text)
                }
            } else {
                debugLog("[FloatingOverlayViewModel] OpenAI key missing, pasting raw text")
                self.copyToClipboard(transcript.text)
                self.pasteToActiveApp()
                self.statusMessage = "Ready"
            }
        } else {
            self.transcript = transcript.text
            self.statusMessage = "Transcribing..."
        }
    }
    
    private func editAndSend(_ text: String) async {
        do {
            let config = UserPreferences.shared.editingConfig
            let edited = try await editingService.editText(text, config: config)
            await MainActor.run {
                self.transcript = edited
                self.copyToClipboard(edited)
                self.pasteToActiveApp()
            }
        } catch {
            debugLog("Editing failed: \(error), using raw text")
            await MainActor.run {
                self.transcript = text
                self.copyToClipboard(text)
                self.pasteToActiveApp()
            }
        }
    }
    
    private func copyToClipboard(_ text: String) {
        debugLog("[FloatingOverlayViewModel] Copying to clipboard: \(text)")
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        if pasteboard.setString(text, forType: .string) {
            debugLog("[FloatingOverlayViewModel] Successfully set clipboard string")
            historyManager.save(text)
            DispatchQueue.main.async {
                self.history.insert(text, at: 0)
                if self.history.count > 50 { self.history.removeLast() }
            }
        } else {
            debugLog("[FloatingOverlayViewModel] Failed to set clipboard string!")
        }
    }
    
    private func pasteToActiveApp() {
        DispatchQueue.main.async {
            debugLog("[FloatingOverlayViewModel] Hiding overlay and app for pasting")
            FloatingOverlayWindow.shared.hide()
            
            // Allow some time for the previous app to regain focus
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                let source = CGEventSource(stateID: .combinedSessionState)
                
                // Command+V
                if let keyVDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) {
                    keyVDown.flags = .maskCommand
                    keyVDown.post(tap: .cgAnnotatedSessionEventTap)
                }
                
                if let keyVUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false) {
                    keyVUp.flags = .maskCommand
                    keyVUp.post(tap: .cgAnnotatedSessionEventTap)
                }
                debugLog("[FloatingOverlayViewModel] Paste command posted")
            }
        }
    }
}
