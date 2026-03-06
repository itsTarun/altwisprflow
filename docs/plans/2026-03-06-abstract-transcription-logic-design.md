# Abstract Transcription Logic Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Abstract the existing transcription logic into a `TranscriptionProvider` protocol and implement the strategy pattern in `FloatingOverlayViewModel` to allow seamless switching between cloud and local providers in the future.

**Architecture:** We will define a `TranscriptionProvider` protocol that specifies the essential methods (`connect`, `sendAudioData`, `disconnect`) and properties (`transcriptPublisher`, `isSessionBegun`). We'll make `AssemblyAITranscriptionService` conform to this protocol. Finally, we'll refactor `FloatingOverlayViewModel` to use a provider factory or strategy property to interact with the current provider instead of hardcoding `AssemblyAITranscriptionService`.

**Tech Stack:** Swift, Combine, Foundation

---

### Task 1: Create the `TranscriptionProvider` protocol

**Files:**

- Create: `Sources/AltWisprFlow/Services/TranscriptionProvider.swift`

**Step 1: Write the minimal implementation**

```swift
import Foundation
import Combine

protocol TranscriptionProvider: AnyObject {
    var transcriptPublisher: AnyPublisher<Transcript, Error> { get }
    var isSessionBegun: Bool { get }

    func connect(sampleRate: Int) throws
    func sendAudioData(_ data: Data)
    func disconnect()
}
```

**Step 2: Commit**

```bash
git add Sources/AltWisprFlow/Services/TranscriptionProvider.swift
git commit -m "feat: define TranscriptionProvider protocol (Issue #1)"
```

### Task 2: Refactor `AssemblyAITranscriptionService` to conform to `TranscriptionProvider`

**Files:**

- Modify: `Sources/AltWisprFlow/Services/AssemblyAITranscriptionService.swift:4`

**Step 1: Update the class signature**

```swift
// Change:
// final class AssemblyAITranscriptionService: ObservableObject {
// To:
final class AssemblyAITranscriptionService: ObservableObject, TranscriptionProvider {
```

_Note: The existing methods (`connect`, `sendAudioData`, `disconnect`, `transcriptPublisher`, `isSessionBegun`) already match the protocol signature perfectly._

**Step 2: Commit**

```bash
git add Sources/AltWisprFlow/Services/AssemblyAITranscriptionService.swift
git commit -m "refactor: conform AssemblyAITranscriptionService to TranscriptionProvider (Issue #1)"
```

### Task 3: Refactor `FloatingOverlayViewModel` to use the strategy pattern

**Files:**

- Modify: `Sources/AltWisprFlow/ViewModels/FloatingOverlayViewModel.swift`

**Step 1: Replace the concrete implementation with the protocol**

```swift
// Change:
// private var transcriptionService = AssemblyAITranscriptionService()
// To:
private var transcriptionService: TranscriptionProvider = AssemblyAITranscriptionService()
```

_Note: For now, we instantiate the AssemblyAI service as the default, but the variable is typed as `TranscriptionProvider`. We don't need a full factory yet until we have a second provider, but this enables the dynamic switching._

**Step 2: Verify the project builds**

Run: `swift build`
Expected: Build succeeds without errors.

**Step 3: Commit**

```bash
git add Sources/AltWisprFlow/ViewModels/FloatingOverlayViewModel.swift
git commit -m "refactor: use TranscriptionProvider in FloatingOverlayViewModel (closes #1)"
```
