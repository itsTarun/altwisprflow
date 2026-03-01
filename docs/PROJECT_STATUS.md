# AltWisprFlow - Project Documentation

## Project Summary
**AltWisprFlow** is a production-ready macOS dictation application designed for high-performance, real-time speech-to-text. It mimics the "Wispr Flow" experience by providing a global hotkey that triggers a floating overlay, transcribes speech in real-time, and automatically pastes the result into the active application.

## Current Progress (Status: Beta)
- ✅ **Global Hotkey:** Registered `Control+Option+Space` via Carbon API for system-wide activation.
- ✅ **Floating Overlay:** Custom `NSWindow` that stays above all apps and follows active screen.
- ✅ **Audio Engine:** Captures system microphone at 48kHz and downsamples to 16kHz Mono PCM for API compatibility.
- ✅ **Speech-to-Text:** Integrated AssemblyAI Universal Streaming (v3) with real-time feedback.
- ✅ **Automation:** Automatically copies results to clipboard and simulates `Command+V` for instant pasting.
- ✅ **Persistence:** SQLite history management using GRDB.
- ✅ **Security:** API keys stored securely in macOS Keychain.
- ✅ **AI Polish:** Optional OpenAI integration to clean up transcripts before pasting.

## Step-by-Step Implementation Journey

1.  **Foundation:** Built the app using **SwiftUI** for settings and **AppKit** for system-level features like floating windows and menu bar integration.
2.  **Carbon Hotkeys:** Since SwiftUI doesn't natively support global hotkeys, we implemented a `HotkeyManager` using the low-level Carbon API to ensure the app responds even when hidden.
3.  **Audio Pipeline:** Developed `AudioCaptureManager` using **AVFoundation**. It handles the complex task of resampling microphone data in real-time and converting 32-bit float audio to 16-bit PCM (Linear Pulse Code Modulation).
4.  **AssemblyAI v3 Integration:** Overcame a major "Model deprecated" blocker by migrating from AssemblyAI's legacy WebSocket API to their new **Universal Streaming (v3)**. Switched from base64 JSON payloads to raw binary binary streams for lower latency and better reliability.
5.  **Synchronization:** Fixed race conditions in the WebSocket handshake. The app now buffers audio and only starts sending after receiving the `SessionBegins` event.
6.  **UX Polish:** Added automatic pasting using `CGEvent` simulation, ensuring the text flows directly into the user's cursor position in apps like Slack, Chrome, or VS Code.

## Architecture & Frameworks

-   **Architecture:** MVVM (Model-View-ViewModel) with Service-oriented approach.
-   **Combine:** Used for reactive data flow between the Audio Engine, Transcription Service, and UI.
-   **KeychainAccess:** Securely wraps macOS Keychain for API key storage.
-   **GRDB.swift:** A high-performance SQLite toolkit used for history persistence.
-   **OpenAI SDK:** Optional service for text correction/polishing.
-   **Carbon & AppKit:** Essential for system-wide events and window management.

## Security & Safety
-   **No Telemetry:** The app is completely private; audio is streamed directly to AssemblyAI with no intermediate logging of speech content.
-   **Encrypted Storage:** API keys are never stored in `UserDefaults` or plain text files. They reside in the macOS Keychain, protected by system-level encryption.
-   **Local History:** Transcriptions are stored in a local SQLite database that never leaves the machine.
-   **Safe Logging:** Debug logs are redirected to `/tmp/altwispr_debug.log` and do not include sensitive API tokens.

## Speech-to-Text Implementation Details
-   **Endpoint:** `wss://streaming.assemblyai.com/v3/ws`
-   **Format:** 16,000Hz, Single Channel, 16-bit Signed Integer PCM (little-endian).
-   **Technique:** Real-time binary streaming. The app sends chunks of audio as they are captured, receiving `PartialTranscript` for UI updates and `FinalTranscript` (triggered by `end_of_turn`) for the final result.

---

## Future: Local STT with MLX-Audio
Research indicates that **MLX-Audio** (built on Apple's MLX framework) is the best path for local, on-device transcription on Apple Silicon.
-   **Capabilities:** Supports Whisper Large v3 Turbo, Voxtral Realtime (4-bit quantization), and MedASR.
-   **Integration Strategy:** Run a local `mlx_audio.server` (OpenAI-compatible) and update our `TranscriptionService` to allow toggling between "Cloud" and "Local" endpoints.
