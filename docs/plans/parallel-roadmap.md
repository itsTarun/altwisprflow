# [Roadmap] AltWisprFlow Parallel Execution Plan

> **For Agents:** Use `superpowers:executing-plans` to implement this plan task-by-track.

**Goal:** Transform AltWisprFlow into a fluid, multi-provider dictation app with local on-device transcription (MLX-Audio) and a "walkie-talkie" style `fn` key interaction.

---

## Phase 1: Core Foundation (Parallelizable)

### **Track A: Architecture Refactor (Agent 1 - High Priority)**

_Decouple the UI from specific AI providers to enable "Local Mode"._

- **Reference Issue:** #1
- **Files:** `TranscriptionProvider.swift` (New), `AssemblyAITranscriptionService.swift`, `FloatingOverlayViewModel.swift`.
- **Tasks:**
  1. Define `TranscriptionProvider` protocol (methods: `connect()`, `disconnect()`, `sendAudioData(_:)`).
  2. Refactor existing AssemblyAI code to conform to this protocol.
  3. Update `FloatingOverlayViewModel` to use dependency injection for the provider.

### **Track B: Advanced Input System (Agent 2 - UX)**

_Implement the "Premium" fn key logic (Push-to-Talk)._

- **Reference Issues:** #3, #5
- **Files:** `HotkeyManager.swift`, `FloatingOverlayWindow.swift`, `AccessibilityManager.swift` (New).
- **Tasks:**
  1. Implement `AccessibilityManager` to check/prompt for macOS Accessibility permissions (required for PTT and Auto-Paste).
  2. Replace Carbon hotkeys with a `CGEventTap` to monitor the **Function (Globe)** key state.
  3. Implement **Push-to-Talk (PTT)**: Record while `fn` is held, paste on release.
  4. Implement **Double-Tap Latch** (400ms window): Rapidly double-pressing `fn` keeps the mic ON (sticky mode).
  5. **Visual Feedback:** Update the overlay with a clear visual indicator (e.g., a "Locked" or "Sticky" icon) when in latched mode.
  6. Implement **Multi-Screen Support**: Move overlay to the screen with the active mouse/focus.

### **Track C: Security & Model Research (Agent 3 - Research)**

_Validate local models and harden credentials._

- **Reference Issues:** #6, #7
- **Files:** `KeychainService.swift`, `SettingsViewModel.swift`.
- **Tasks:**
  1. Abstract `KeychainService` to support multiple service credentials.
  2. Benchmark **MLX-Audio** vs **WhisperKit** latency on the local device.
  3. Create the `LocalMLXProvider` boilerplate based on Track A's protocol.

---

## Phase 2: Integration & UI (Sequential)

### **Track D: Local Integration (Agent 1)**

_Connect the final Local AI engine._

- **Reference Issue:** #2
- **Dependency:** Track A & C complete.
- **Tasks:**
  1. Connect the 16kHz audio stream to the MLX engine.
  2. Ensure real-time "partial" results are published to the `transcriptPublisher`.

### **Track E: UI & Settings (Agent 2)**

_Give users control over the new features._

- **Reference Issue:** #4
- **Tasks:**
  1. Add the "Cloud vs Local" switch in the Settings UI.
  2. **Download UI:** If "Local Mode" is selected and the model is missing, show a **Download Progress Bar** with a "Download" button.
  3. Update `UserPreferences` to persist the chosen transcription mode.
