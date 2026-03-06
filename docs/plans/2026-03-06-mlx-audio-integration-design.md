# MLX-Audio Local Transcription Design

## Goal
Integrate `mlx-swift` and `mlx-audio-swift` natively into the macOS app to provide 100% private, on-device transcription via a `LocalMLXProvider` that conforms to the `TranscriptionProvider` protocol. The app will automatically download a quantized Whisper model (e.g., `distil-whisper-large-v3-mlx-4bit`) on first use.

## Architecture

1. **Dependency Injection**: Add `apple/mlx-swift` and `apple/mlx-swift-examples` (specifically the Whisper audio components) to `Package.swift`.
2. **Provider Implementation**: Create `LocalMLXProvider.swift` conforming to `TranscriptionProvider`.
   - **`connect()`**: Will trigger the asynchronous download of the model weights from HuggingFace (if not already downloaded) to the App Support directory, and then load the model into MLX memory.
   - **`sendAudioData()`**: Will buffer incoming 16kHz PCM audio and periodically run inference using the MLX model to generate transcripts.
   - **`transcriptPublisher`**: Will emit `Transcript` objects. We need to implement a streaming/chunking logic to emit partial results (isFinal: false) and final results when silence is detected or recording stops.
3. **Model Management**: Create a `ModelDownloader` utility class responsible for:
   - Checking if the model exists in `~/Library/Application Support/AltWisprFlow/Models/`.
   - Downloading the model files (`.safetensors`, `config.json`, `tokenizer.json`) if missing.
   - Providing progress updates (which can be piped to the UI's `statusMessage`).
4. **Audio Processing**: The incoming raw PCM data from `AudioCaptureManager` needs to be converted into the appropriate floating-point tensor format expected by the MLX Whisper model.

## Data Flow
1. User hits recording toggle -> `FloatingOverlayViewModel` calls `connect()` on `LocalMLXProvider`.
2. `LocalMLXProvider` checks for model -> downloads if missing -> loads model to GPU.
3. Audio flows from `AudioCaptureManager` -> `LocalMLXProvider` -> MLX Model Inference.
4. Model yields text -> Provider maps to `Transcript` struct -> View updates.

## Error Handling & Edge Cases
- **No Internet on First Run**: If the user tries to use local mode for the first time without an internet connection to download the model, we emit an error stating "Model download required for first use. Please connect to the internet."
- **Insufficient Memory**: MLX will throw if it cannot allocate memory for the model. We must catch initialization errors and present a clear message.
