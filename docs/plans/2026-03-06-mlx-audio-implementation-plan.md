# MLX-Audio Integration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Integrate Apple's MLX Swift packages to provide a completely local, offline transcription capability.

**Architecture:** We will add the `mlx-swift` dependencies to `Package.swift`. Next, we'll implement a `ModelDownloader` utility to fetch HuggingFace model weights automatically on first run. Finally, we'll build `LocalMLXProvider` which conforms to our newly created `TranscriptionProvider` protocol to stream and run inference on the audio data.

**Tech Stack:** Swift, MLX (Apple's Machine Learning framework), Foundation

---

### Task 1: Add MLX Dependencies to `Package.swift`

**Files:**
- Modify: `Package.swift`

**Step 1: Add dependencies to Package.swift**
Update `dependencies` to include `mlx-swift` and `hub`. Update the `targets` array to link `MLX` and `Hub`.

```swift
    dependencies: [
        // existing dependencies...
        .package(url: "https://github.com/ml-explore/mlx-swift.git", from: "0.20.0"),
        .package(url: "https://github.com/huggingface/swift-chat.git", from: "0.1.0") // Usually contains the 'Hub' package needed for easy model downloading
    ],
    targets: [
        .executableTarget(
            name: "AltWisprFlow",
            dependencies: [
                // existing...
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "Hub", package: "swift-chat")
            ],
            // ...
```
*(Note: As `swift-chat` may not be the exact hub package used universally, we will instead just use `URLSession` to download the specific whisper files directly from huggingface to avoid complex dependency trees if `Hub` isn't readily available. Let's stick to manually downloading the 3-4 required files for simplicity and control).*

**Wait, simpler approach for Task 1:** Let's just add `mlx-swift` and `mlx-audio-swift`. `mlx-audio-swift` has the whisper implementation.

```swift
    dependencies: [
        // existing dependencies...
        .package(url: "https://github.com/ml-explore/mlx-swift.git", from: "0.20.0"),
        .package(url: "https://github.com/ml-explore/mlx-audio-swift.git", from: "0.1.0") // Assuming standard MLX audio package structure
    ],
    targets: [
        .executableTarget(
            name: "AltWisprFlow",
            dependencies: [
                // existing...
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "MLXAudio", package: "mlx-audio-swift")
            ],
            // ...
```
*(Correction: Apple's MLX example for Whisper is usually embedded in `mlx-swift-examples/Libraries/Audio`. We will need to investigate exactly which package exposes the Whisper model in MLX for Swift. Let's first search Github for the correct package URL for MLX Audio).*

**Revised Task 1 (Research & Add Dependency):**
We need to run a web search to find the correct Swift package for MLX Audio (Whisper) and add it to `Package.swift`.

**Step 1: Write the minimal implementation**
We'll update `Package.swift` with the correct `mlx-swift` repository.

**Step 2: Verify the project builds**
Run `swift package resolve` to ensure it fetches.

**Step 3: Commit**
`git commit -m "chore: add mlx-swift dependencies"`

---

### Task 2: Create ModelDownloader

**Files:**
- Create: `Sources/AltWisprFlow/Services/ModelDownloader.swift`

**Step 1: Implement the downloader**
Create a class that uses `URLSession` to download `.safetensors` and `config.json` files from HuggingFace (e.g., `mlx-community/whisper-tiny-mlx-4bit`) into the App Support directory.

**Step 2: Commit**
`git commit -m "feat: implement ModelDownloader for MLX Whisper weights"`

---

### Task 3: Implement LocalMLXProvider

**Files:**
- Create: `Sources/AltWisprFlow/Services/LocalMLXProvider.swift`

**Step 1: Implement the provider**
Create a class conforming to `TranscriptionProvider`. In `connect()`, call the downloader. In `sendAudioData()`, buffer the audio. Run a background loop that feeds the audio buffer into the MLX Whisper model and publishes `Transcript` events.

**Step 2: Commit**
`git commit -m "feat: implement LocalMLXProvider with MLX Whisper (closes #2)"`

