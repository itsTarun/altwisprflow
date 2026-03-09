# Transcription Mode Toggle Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create a UI toggle in the Settings screen to allow switching between AssemblyAI (Cloud) and MLX (Local) providers.

**Architecture:** Add an `@AppStorage` enum called `TranscriptionMode` to `SettingsView.swift` and `FloatingOverlayViewModel.swift`. The ViewModel will dynamically swap the provider in its `transcriptionService` variable based on this setting. We'll disable the toggle when `isRecording` is true to prevent mid-recording backend swaps.

**Tech Stack:** SwiftUI, Combine, AppStorage

---

### Task 1: Create the TranscriptionMode Enum

**Files:**
- Create: `Sources/AltWisprFlow/Models/TranscriptionMode.swift`

**Step 1: Write the Enum**
Create an enum backed by a String (so it can be stored in `AppStorage`).

```swift
import Foundation

public enum TranscriptionMode: String, CaseIterable, Identifiable {
    case cloud = "AssemblyAI (Cloud)"
    case local = "MLX (Local - Offline)"
    
    public var id: String { self.rawValue }
}
```

**Step 2: Commit**
`git add Sources/AltWisprFlow/Models/TranscriptionMode.swift`
`git commit -m "feat: define TranscriptionMode enum"`

---

### Task 2: Implement the Toggle in SettingsView

**Files:**
- Modify: `Sources/AltWisprFlow/Views/SettingsView.swift`

**Step 1: Add `@AppStorage` and Picker**
Inside the main `Form`, add a new `Section("Transcription Backend")`. 
Add a `@AppStorage("transcriptionMode") private var transcriptionMode: TranscriptionMode = .cloud`.
Add a Picker bound to this variable.
Disable the picker if `overlayVM.isRecording` is true.

**Step 2: Commit**
`git add Sources/AltWisprFlow/Views/SettingsView.swift`
`git commit -m "feat: add Transcription Backend picker to SettingsView (Issue #4)"`

---

### Task 3: Wire the Toggle in FloatingOverlayViewModel

**Files:**
- Modify: `Sources/AltWisprFlow/ViewModels/FloatingOverlayViewModel.swift`

**Step 1: Swap Providers dynamically**
Add `@AppStorage("transcriptionMode") private var transcriptionMode: TranscriptionMode = .cloud`.
Inside `startRecording()`, right before calling `transcriptionService.connect()`, instantiate the correct provider:
```swift
if transcriptionMode == .local {
    self.transcriptionService = LocalMLXProvider()
} else {
    self.transcriptionService = AssemblyAITranscriptionService()
}
// We also must re-setup the binding whenever we swap the service instance!
setupTranscriptionBinding()
```
*Note: Because we are swapping the entire `transcriptionService` object, we must extract the `transcriptionService.transcriptPublisher.sink` logic from `setupBindings()` into a new helper function `setupTranscriptionBinding()` and cancel the old subscription before creating a new one!*

**Step 2: Commit**
`git add Sources/AltWisprFlow/ViewModels/FloatingOverlayViewModel.swift`
`git commit -m "feat: wire transcriptionMode to dynamically swap providers (closes #4)"`

