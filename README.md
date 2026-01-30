# AssemblyAI Streaming STT Flutter Example

A complete Flutter application demonstrating real-time speech-to-text using AssemblyAI's streaming API v3. This example project showcases how to implement live audio transcription with amplitude visualization and multi-language support.

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)
![AssemblyAI](https://img.shields.io/badge/AssemblyAI-FF6B6B?style=for-the-badge)

## ✨ Features

- 🎙️ **Real-time speech transcription** using AssemblyAI streaming API v3
- 🌍 **Multi-language support**: English, Spanish, French, German, Italian, Portuguese
- 🔄 **Automatic language detection**
- 📊 **Live amplitude visualization** with animated waveforms
- 🎯 **High accuracy** with confidence scores display
- 📱 **Android ready** with proper permissions handling
- 🎨 **Modern Material 3 UI**
- 🔧 **Clean architecture** with separation of concerns

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.8.1)
- Android Studio / Xcode for mobile development
- AssemblyAI API Key ([Get one here](https://assemblyai.com/dashboard))

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/assembly_ai_flutter_example.git
   cd assembly_ai_flutter_example
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure your API key**
   - Copy `.env.example` to `.env`
   - Replace `your_api_key_here` with your actual AssemblyAI API key
   ```bash
   cp .env.example .env
   ```

4. **Run the application**
   ```bash
   flutter run
   ```

## 🔧 Configuration

### AssemblyAI API Key Setup

1. Sign up at [AssemblyAI](https://assemblyai.com/)
2. Get your API key from the [dashboard](https://assemblyai.com/dashboard)
3. Enter it in the app when prompted, or configure it in the app settings

### Audio Settings

The app is pre-configured with optimal settings for AssemblyAI:
- **Sample Rate**: 16kHz
- **Encoding**: PCM 16-bit (s16le)
- **Channels**: Mono
- **Speech Model**: `universal-streaming-multilingual`

## 📱 Android Setup

### Permissions

The app automatically handles the following permissions:
- `RECORD_AUDIO` - Required for microphone access
- `INTERNET` - Required for AssemblyAI API communication
- `WRITE_EXTERNAL_STORAGE` - For temporary audio file storage

### Minimum SDK

- **Minimum SDK**: API 24 (Android 7.0)
- **Target SDK**: API 34

## 🏗️ Architecture

```
lib/
├── config/
│   └── app_config.dart          # App configuration constants
├── screens/
│   └── stt_screen.dart          # Main STT interface
├── services/
│   ├── assembly_ai_service.dart # WebSocket communication
│   └── audio_service.dart       # Audio recording & processing
├── widgets/
│   ├── amplitude_visualizer.dart # Audio visualization
│   └── transcript_display.dart   # Transcript UI components
└── main.dart                    # App entry point
```

### Key Components

#### AssemblyAIService
Handles WebSocket connection to AssemblyAI's streaming API v3:
- Real-time audio streaming
- Configuration management
- Message parsing and error handling

#### AudioService
Manages audio recording and processing:
- Microphone permission handling
- Real-time amplitude monitoring
- Audio format conversion for AssemblyAI compatibility

#### AmplitudeVisualizer
Provides visual feedback for audio input:
- Animated waveform display
- Circular amplitude indicator
- Customizable colors and effects

#### TranscriptDisplay
Shows real-time transcription results:
- Live transcript updates
- Confidence score indicators
- Language detection display
- Transcript history management

## 🌍 Supported Languages

The app supports automatic detection and transcription of:

| Language | Code | Status |
|----------|------|--------|
| English | `en` | ✅ Full support |
| Spanish | `es` | ✅ Full support |
| French | `fr` | ✅ Full support |
| German | `de` | ✅ Full support |
| Italian | `it` | ✅ Full support |
| Portuguese | `pt` | ✅ Full support |

## 🔌 API Integration

### WebSocket Connection

The app connects to AssemblyAI's real-time streaming endpoint (v2 API):
```
wss://api.assemblyai.com/v2/realtime/ws?sample_rate=16000
```

**Authentication:** WebSocket subprotocols: `['token', 'your_api_key_here']`

### Message Format

**Audio Data (Client to Server):**
```json
{
  "audio_data": "base64_encoded_audio_bytes"
}
```

**Session Termination (Client to Server):**
```json
{
  "terminate_session": true
}
```

**Transcript Response (Server to Client):**
```json
{
  "message_type": "FinalTranscript",
  "text": "Hello, this is a test transcription.",
  "confidence": 0.95,
  "words": [
    {
      "text": "Hello",
      "start": 0,
      "end": 500,
      "confidence": 0.98
    }
  ]
}
```

### Session Flow
1. Connect to WebSocket with API key in subprotocols
2. Receive `SessionBegins` message
3. Send base64-encoded audio chunks as JSON messages
4. Receive `PartialTranscript` and `FinalTranscript` messages
5. Send `terminate_session` message when done
6. Receive `SessionTerminated` message

## 🛠️ Development

### Adding New Features

1. **New Languages**: Update `supportedLanguages` in `AppConfig`
2. **Custom Visualizers**: Extend `AmplitudeVisualizer` widget
3. **Audio Processing**: Modify `AudioService` for custom formats
4. **UI Themes**: Update theme configuration in `main.dart`

### Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/

# Analyze code
flutter analyze
```

### Building

```bash
# Build APK
flutter build apk

# Build AAB for Play Store
flutter build appbundle

# Build iOS (macOS only)
flutter build ios
```

## 🐛 Troubleshooting

### Common Issues

**Connection Problems:**
- Verify your API key is correct and account is upgraded (payment method required)
- Check internet connectivity
- Ensure WebSocket connections aren't blocked by firewall
- Error 402: Payment required - upgrade your AssemblyAI account
- Error 401/403: Invalid API key - check your credentials

**Audio Issues:**
- Grant microphone permissions
- Test with different audio sources
- Check device audio settings

**Build Errors:**
- Run `flutter clean && flutter pub get`
- Update Flutter SDK to latest stable version
- Check Android SDK requirements

### Debug Mode

Enable debug logging by setting debug flags in the services:
```dart
// In assembly_ai_service.dart
static const bool enableDebugLogging = true;
```

## 📊 Performance Tips

1. **Optimize Audio Streaming**: Use appropriate buffer sizes
2. **Memory Management**: Clear transcript history periodically
3. **Network Efficiency**: Monitor WebSocket connection health
4. **Battery Usage**: Implement recording timeout for long sessions

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Resources

- [AssemblyAI Documentation](https://www.assemblyai.com/docs)
- [Flutter Documentation](https://docs.flutter.dev/)
- [AssemblyAI Dashboard](https://assemblyai.com/dashboard)
- [Flutter Audio Packages](https://pub.dev/packages/record)

## 📞 Support

- 📧 Email: your-email@example.com
- 🐛 Issues: [GitHub Issues](https://github.com/your-username/assembly_ai_flutter_example/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/your-username/assembly_ai_flutter_example/discussions)

---

Made with ❤️ and Flutter
