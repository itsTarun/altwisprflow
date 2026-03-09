# WhisperKit Offline Transcription Design

## Goal
Integrate `WhisperKit` natively into the macOS app to provide 100% private, offline transcription via a `LocalWhisperKitProvider` that conforms to the `TranscriptionProvider` protocol. This bypasses the need for Xcode to compile heavy C++ machine learning libraries because WhisperKit uses Apple's native CoreML framework.

## Architecture

1. **Dependency Injection**: Add `argmaxinc/WhisperKit` to `Package.swift`.
2. **Provider Implementation**: Create `LocalWhisperKitProvider.swift` conforming to `TranscriptionProvider`.
   - **`connect()`**: WhisperKit has an automatic `WhisperKit(model: "whisper-base")` initializer that automatically downloads the required CoreML model from HuggingFace to the App Support directory and compiles it for the Neural Engine.
   - **`sendAudioData()`**: WhisperKit expects a continuous audio stream. We will feed the 16kHz PCM audio buffer into `whisperKit.transcribe(audioArray)`.
   - **`transcriptPublisher`**: Will emit `Transcript` objects. We can leverage WhisperKit's streaming capabilities to emit partial results (isFinal: false) and final results.
3. **Data Flow**: The incoming raw PCM data from `AudioCaptureManager` needs to be converted into the appropriate floating-point array format expected by WhisperKit.

## Error Handling & Edge Cases
- **No Internet on First Run**: WhisperKit will throw an error if the model isn't cached locally and there is no internet. We will catch this and notify the user via `statusMessage`.
- **First-Time Compilation Delay**: The first time a CoreML model is downloaded, macOS takes 30-60 seconds to "compile" the `.mlpackage` for the Neural Engine. The user must see a "Optimizing model for your Mac... this only happens once" message to avoid thinking the app froze.
