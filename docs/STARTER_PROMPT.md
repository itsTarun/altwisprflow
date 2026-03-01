# New Session Starter: Integrating MLX-Audio Local STT

Copy and paste the prompt below into a new chat session to continue development with a fresh context.

---

## The Prompt

I am working on **AltWisprFlow**, a production-ready macOS voice dictation app. The app is currently functional using **AssemblyAI v3 (WebSocket)** for real-time cloud transcription.

### Current Technical State:

- **Language/Framework:** Swift 5.9+, SwiftUI, AppKit, Combine.
- **Global Hotkey:** `Control+Option+Space` (implemented via Carbon API).
- **Audio Pipeline:** `AVAudioEngine` capturing microphone input at 48kHz and downsampling to **16kHz Mono PCM (16-bit Signed Integer)** using `AVAudioConverter`.
- **Transcription Service:** `AssemblyAITranscriptionService.swift` handles real-time binary streaming to `wss://streaming.assemblyai.com/v3/ws`.
- **Automation:** Uses `CGEvent` to simulate `Command+V` and paste text directly into the active application's cursor position.
- **Security:** API keys are stored securely in **macOS Keychain** using `KeychainAccess`.
- **Persistence:** Local history is stored in SQLite via **GRDB**.

### Project Goal:

Integrate **MLX-Audio** (https://github.com/Blaizzy/mlx-audio) to provide a high-performance **local, on-device transcription** option optimized for Apple Silicon (M1/M2/M3/M4).

### Tasks for this Session:

1.  **Architecture Refactor:** Abstract the transcription logic. Create a `TranscriptionProvider` protocol so the app can easily switch between `AssemblyAIProvider` (Cloud) and `MLXProvider` (Local).
2.  **STT Model Research & Integration:**
    - **Primary:** Integrate **MLX-Audio** (https://github.com/Blaizzy/mlx-audio). Evaluate using the `mlx-audio-swift` package vs. running a local OpenAI-compatible server via `mlx_audio.server`.
    - **Exploration:** Briefly research other high-performance local alternatives like `WhisperKit` or `sherpa-onnx` if MLX presents integration hurdles.
    - **Hybrid Support:** Ensure the provider architecture allows seamless switching between AssemblyAI (Cloud) and the local model based on user preference or network availability.
    - **Feeding Audio:** Implement a provider that feeds our existing 16kHz PCM audio stream into the chosen local model.
3.  **New Global Hotkey Logic (`fn` key):**
    - Replace the current `Control+Option+Space` hotkey in `HotkeyManager.swift`.
    - Implement a **hybrid "fn" key** listener (likely using `CGEventTap` or `NSEvent.addGlobalMonitorForEvents` for `.flagsChanged`).
    - **Behavior:**
      - **Push-to-Talk:** Hold the `fn` key to keep the mic on; release to stop and paste.
      - **Double-Press Toggle:** Rapidly double-pressing `fn` should "latch" the mic ON (sticky recording). A single press while it's latched should turn it OFF.
4.  **UI Updates:** Add a "Transcription Mode" toggle in `SettingsView.swift` to allow the user to choose between "Cloud (AssemblyAI)" and "Local (Apple Silicon)".
5.  **Streaming Parity:** Ensure the local model provides real-time partial transcripts to keep the floating overlay's "live" feel.

### Reference Files:

- `Sources/AltWisprFlow/Services/AssemblyAITranscriptionService.swift` (Current STT logic)
- `Sources/AltWisprFlow/Services/AudioCaptureManager.swift` (Audio stream source)
- `Sources/AltWisprFlow/ViewModels/FloatingOverlayViewModel.swift` (Orchestration logic)

Please start by analyzing the current codebase and proposing the protocol-oriented refactor for multiple providers.
