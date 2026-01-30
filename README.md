# AssemblyAI Streaming STT (Flutter)

Minimal Flutter sample that records microphone audio, streams it to AssemblyAI's real-time API, and shows live transcripts plus a numeric amplitude indicator.

## Requirements

- Flutter 3.8 or newer
- Android/iOS device or emulator with microphone access
- AssemblyAI API key (create one at https://assemblyai.com/dashboard)

## Quick Start

```bash
flutter pub get
flutter run
```

The app prompts for your AssemblyAI API key the first time you tap the cloud icon. Enter the key, connect, then tap the mic button to begin streaming audio.

## Project Layout

| Path | Purpose |
| --- | --- |
| `lib/main.dart` | Entry point and global theme |
| `lib/screens/stt_screen.dart` | Main UI: connection controls, recording button, transcript view |
| `lib/services/assembly_ai_service.dart` | WebSocket client for AssemblyAI streaming API |
| `lib/services/audio_service.dart` | Microphone capture and amplitude calculation via `flutter_sound` |
| `lib/widgets` | Reusable UI pieces (amplitude readout, transcript paragraph) |

## Development

- Analyze code: `flutter analyze`
- Run tests: `flutter test`
- Build release artifacts: `flutter build apk` or `flutter build ios`

## Notes

- Audio is captured as PCM16 @ 16 kHz mono to match AssemblyAI requirements.
- Transcripts display as a rolling paragraph with basic capitalization/punctuation cleanup.
- No credentials are stored; you must enter the API key again after reinstalling the app.
