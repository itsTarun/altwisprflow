# Transcription Mode Toggle Design

## Goal
Implement a UI toggle in the Settings screen that allows the user to switch between "Cloud (AssemblyAI)" and "Local (MLX)" transcription modes. The `FloatingOverlayViewModel` must respect this setting and use the appropriate `TranscriptionProvider`.

## Architecture

1. **State Management**: Use SwiftUI's `@AppStorage` to persist the selected `TranscriptionMode` (an enum: `.cloud`, `.local`) in `UserDefaults`.
2. **Settings UI**: Add a `Picker` in `SettingsView.swift` under a new "Transcription Backend" section.
3. **ViewModel Integration**: `FloatingOverlayViewModel` will read this `@AppStorage` value. When `toggleRecording()` is called, it will instantiate either `AssemblyAITranscriptionService` or `LocalMLXProvider` based on the current setting, ensuring the correct provider is used dynamically.

## Data Flow
- User opens Settings -> Selects "Local (MLX)" from Picker.
- `@AppStorage` updates `UserDefaults` immediately.
- User triggers recording hotkey -> `FloatingOverlayViewModel` checks the current `@AppStorage` value.
- If `.local`, it uses `LocalMLXProvider`.
- Audio streams to the local provider -> Mock transcripts appear in the overlay.

## Edge Cases
- **Switching while recording**: We should ideally prevent changing the backend *while* a recording is active, or we must stop the current recording before switching providers. For simplicity, we will disable the Picker in the UI if `FloatingOverlayViewModel.shared.isRecording` is true.
