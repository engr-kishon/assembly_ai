# AssemblyAI Real-Time STT Flutter App

A production-style Flutter application that captures microphone input, streams it to AssemblyAI's v3 streaming API, and renders polished live transcripts plus a numeric amplitude readout. This project is optimized for demos and Medium write-ups: it has a clean Material 3 UI, clear architecture boundaries, and setup steps that anyone with Flutter experience can follow.

---

## Why This Project?

- **Showcase real-time AI** – demonstrate how quickly AssemblyAI can stream transcripts back to a mobile UI.
- **Practical Flutter patterns** – highlight provider-ready services, stateful widgets, and reusable UI building blocks.
- **Easy to extend** – plug in custom visualizers, new languages, or additional analytics without touching the core flow.

---

## Features

- Real-time PCM16 audio capture at 16 kHz mono using `flutter_sound`.
- WebSocket client targeting `wss://streaming.assemblyai.com/v3/ws` with configurable speech model and language detection.
- Transcript area that stitches partial and final responses into readable paragraphs with auto punctuation cleanup.
- Amplitude indicator that displays RMS-based loudness (0–100) derived from the same audio stream sent to AssemblyAI.
- Material 3 interface with connection status, error banners, and permission prompts.
- Modular service layer (`AudioService`, `AssemblyAIService`) for easy testing or reuse.

---

## Quick Start

### 1. Prerequisites

- Flutter SDK 3.8 or newer (FVM compatible).
- Android emulator/device or iOS simulator/device with microphone access.
- AssemblyAI account with an API key: https://assemblyai.com/dashboard.

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Run the App

```bash
flutter run
```

When the UI loads:

1. Tap the cloud icon in the top bar.
2. Paste your AssemblyAI API key and connect.
3. Tap the microphone button to start streaming audio.
4. Speak into the mic; transcripts and amplitude updates appear instantly.

---

## Project Structure

```
lib/
├─ main.dart                    # App entry point and Material theme
├─ config/app_config.dart       # AssemblyAI endpoints, audio constants, UI defaults
├─ screens/stt_screen.dart      # Main screen: connection + recording controls
├─ services/
│   ├─ assembly_ai_service.dart # WebSocket connection, transcript parsing
│   └─ audio_service.dart       # Microphone capture + RMS amplitude calculation
└─ widgets/
    ├─ amplitude_visualizer.dart # Numeric amplitude readout
    └─ transcript_display.dart   # Paragraph-style transcript viewer
```

The separation keeps audio, networking, and UI loosely coupled so each part can be showcased independently in documentation or talks.

---

## How It Works

1. **Permissions & Audio** – `AudioService` requests microphone access, initializes `flutter_sound`, and exposes two streams: raw PCM chunks and amplitude percentages.
2. **Streaming** – `AssemblyAIService` opens a WebSocket to AssemblyAI with query params for sample rate, encoding, speech model, and language detection.
3. **Chunking** – Audio bytes are buffered into 100 ms (3,200 byte) chunks for smooth streaming before being written as binary frames to the socket.
4. **Transcript Events** – Incoming JSON messages are parsed into `TranscriptResponse` objects, distinguishing partial vs. final transcripts.
5. **UI Updates** – `STTScreen` listens to transcript and amplitude streams, updating `TranscriptDisplay` and `AmplitudeVisualizer` inside a responsive Material layout.

---

## Configuration Highlights

| Setting | Default | Location |
| --- | --- | --- |
| AssemblyAI endpoint | `wss://streaming.assemblyai.com/v3/ws` | `AppConfig` |
| Speech model | `universal-streaming-multilingual` | `AppConfig` |
| Sample rate | 16,000 Hz | `AppConfig` + `AudioService` |
| Encoding | PCM 16-bit little endian | `AudioService` + `AssemblyAIService` |
| Language detection | Enabled | `AppConfig` |

Modify `lib/config/app_config.dart` or pass new values into the services to experiment with different models or regions.

---

## Demo Checklist (Great for Medium Articles)

1. Show a short clip of connecting and speaking a sentence in different languages; the transcript updates with minimal latency.
2. Highlight the amplitude percentage moving in sync with your voice to prove both audio capture and normalization work.
3. Pull up `assembly_ai_service.dart` to explain the WebSocket parameters and AssemblyAI streaming workflow.
4. Mention how easily you could add features like word-level timing, speaker labels, or custom visualizers by extending the provided widgets.

---

## Development Scripts

```bash
flutter analyze   # static analysis
flutter test      # widget/unit tests (add your own)
flutter build apk # release build for Android
flutter build ios # release build for iOS (macOS only)
```

---

## Troubleshooting Tips

- **401/403 errors**: Double-check the API key and ensure the account is active.
- **402 payment required**: AssemblyAI needs a billing method for streaming.
- **Socket/timeout issues**: Verify internet connectivity and confirm the device/emulator allows WebSocket traffic.
- **No microphone input**: Ensure permissions are granted in the OS settings and that no other app is locking the mic.

---

## License

This project is distributed under the MIT License. Customize, fork, and share it freely with attribution.

---

### Need Ideas for Next Steps?

- Add persistent API key storage using `shared_preferences`.
- Visualize word-level confidence or detected language badges inline.
- Record and replay past sessions for offline testing.
- Port the audio layer to desktop Flutter for cross-platform demos.

Tag me if you feature this build in your Medium story—I would love to amplify it!
