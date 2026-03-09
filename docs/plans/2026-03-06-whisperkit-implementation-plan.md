# WhisperKit Integration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Integrate Apple's CoreML-based WhisperKit to provide a completely local, offline transcription capability without requiring C++ compilation.

**Architecture:** We will add the `WhisperKit` dependencies to `Package.swift`. Next, we'll implement `LocalWhisperKitProvider` which conforms to our `TranscriptionProvider` protocol. We will handle downloading/initializing the CoreML model and feed the audio buffer into the inference engine.

**Tech Stack:** Swift, WhisperKit, Foundation, Combine

---

### Task 1: Add WhisperKit Dependency to `Package.swift`

**Files:**
- Modify: `Package.swift`

**Step 1: Add dependencies to Package.swift**
Update `dependencies` to include `WhisperKit`. Note: we are also going to remove the `mlx-swift` and `mlx-audio-swift` packages to ensure compilation doesn't fail due to missing C++ headers.

```swift
    dependencies: [
        // existing dependencies...
        .package(url: "https://github.com/argmaxinc/WhisperKit", from: "0.9.0")
    ],
    targets: [
        .executableTarget(
            name: "AltWisprFlow",
            dependencies: [
                // existing...
                .product(name: "WhisperKit", package: "WhisperKit")
            ],
            // ...
```

**Step 2: Verify the project builds**
Run `swift package resolve` to ensure it fetches correctly. (We also run `swift build` to prove that removing MLX fixed our compilation).

**Step 3: Commit**
`git commit -m "chore: swap mlx dependencies for WhisperKit"`

---

### Task 2: Implement LocalWhisperKitProvider

**Files:**
- Create: `Sources/AltWisprFlow/Services/LocalWhisperKitProvider.swift`

**Step 1: Implement the provider**
Create a class conforming to `TranscriptionProvider`. 

**In `connect()`:** Initialize `WhisperKit(model: "openai_whisper-tiny")`. We want a fast, lightweight local model for streaming. Note that `WhisperKit` has an async initializer that handles downloading the model from HuggingFace to a cache directory for us. Update `transcriptSubject` to say "Downloading CoreML Model... (this takes a minute)" and then "Optimizing for Mac..." to keep the user informed.

**In `sendAudioData()`:** Buffer incoming 16kHz PCM audio (`Data`). Convert it to a `[Float]` array. WhisperKit handles audio chunks very well via `whisperKit.transcribe(audioArray)`.

**Step 2: Commit**
`git commit -m "feat: implement LocalWhisperKitProvider (closes #7)"`

---

### Task 3: Temporarily wire it to FloatingOverlayViewModel

**Files:**
- Modify: `Sources/AltWisprFlow/ViewModels/FloatingOverlayViewModel.swift`

**Step 1: Wire up LocalWhisperKitProvider**
Change `transcriptionService: TranscriptionProvider` to use `LocalWhisperKitProvider()` instead of `AssemblyAITranscriptionService()` temporarily so you can test it locally. (In Issue #4, we will add the UI toggle, but for now we just want to prove it works offline).

**Step 2: Commit**
`git commit -m "chore: wire LocalWhisperKitProvider to FloatingOverlayViewModel"`

