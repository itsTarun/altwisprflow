# AltWisprFlow

AI-powered voice dictation for macOS - transcribe speech to text 4x faster with intelligent editing.

## Features

- Real-time voice-to-text transcription with AssemblyAI
- GPT-4o powered editing and grammar correction
- Filler word removal (um, uh, like, you know)
- Grammar correction and punctuation formatting
- Tone matching per application (email, chat, documents)
- Personal dictionary for custom words
- Snippets library for reusable text
- Floating overlay UI with live preview
- Global keyboard shortcut (Control+Option+Space)
- Works in any application (paste to active app)

## Requirements

- macOS 13.0+
- Xcode 15+
- Swift 5.9+
- Microphone access
- Internet connection (for AI APIs)

## Setup

1. **Get API Keys:**
   - [AssemblyAI](https://www.assemblyai.com) - Get API key (100 hours/month free)
   - [OpenAI](https://platform.openai.com) - Get API key ($5 credit for new accounts)

2. **Configure API keys in Settings:**
   - Open app settings
   - Enter AssemblyAI and OpenAI API keys
   - Save settings (stored securely in Keychain)

3. **Build and run:**
   ```bash
   swift build
   swift run
   ```

## Usage

Press `Control + Option + Space` to activate dictation. Speak naturally and text will be transcribed, edited, and pasted to your active application automatically.

## Architecture

The app follows a modular architecture with separate services for audio capture, transcription (AssemblyAI), AI editing (OpenAI), and secure credential storage (Keychain).

## Testing

```bash
swift test
```

## License

MIT
