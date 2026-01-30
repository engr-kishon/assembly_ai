import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';

class AudioService {
  FlutterSoundRecorder? _recorder;
  StreamController<double>? _amplitudeController;
  StreamController<Uint8List>? _audioStreamController;
  StreamSubscription<Uint8List>? _amplitudeSubscription;
  bool _isRecording = false;
  bool _isInitialized = false;

  Stream<double>? get amplitudeStream => _amplitudeController?.stream;
  Stream<Uint8List>? get audioDataStream => _audioStreamController?.stream;
  bool get isRecording => _isRecording;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _recorder = FlutterSoundRecorder(logLevel: Level.off);
    await _recorder!.openRecorder();
    _isInitialized = true;
  }

  Future<bool> requestPermissions() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  Future<bool> hasPermission() async {
    final status = await Permission.microphone.status;
    return status == PermissionStatus.granted;
  }

  Future<void> startRecording() async {
    print('🎤 AudioService: Starting recording...');
    if (_isRecording) {
      print('⚠️ AudioService: Already recording, skipping');
      return;
    }

    if (!_isInitialized) {
      print('🔧 AudioService: Initializing recorder...');
      await initialize();
    }

    final hasPermission = await this.hasPermission();
    if (!hasPermission) {
      print('🔐 AudioService: Requesting microphone permissions...');
      final granted = await requestPermissions();
      if (!granted) {
        print('❌ AudioService: Microphone permission denied');
        throw Exception('Microphone permission not granted');
      }
      print('✅ AudioService: Microphone permission granted');
    }

    try {
      print('📡 AudioService: Creating stream controllers...');
      _amplitudeController = StreamController<double>.broadcast();
      _audioStreamController = StreamController<Uint8List>.broadcast();

      print('🎵 AudioService: Starting recorder with config:');
      print('   - Codec: PCM16');
      print('   - Sample Rate: 16000Hz');
      print('   - Channels: 1 (Mono)');
      print('   - Output: Real-time stream');

      // Start recorder to stream directly (real-time streaming)
      await _recorder!.startRecorder(
        toStream: _audioStreamController!.sink,
        codec: Codec.pcm16,
        sampleRate: 16000,
        numChannels: 1,
      );
      
      _isRecording = true;
      print('✅ AudioService: Recording started successfully');

      // Start amplitude monitoring
      _startAmplitudeMonitoring();
      print('📊 AudioService: Amplitude monitoring started');

    } catch (e) {
      print('❌ AudioService: Failed to start recording: $e');
      throw Exception('Failed to start recording: $e');
    }
  }

  void _startAmplitudeMonitoring() {
    _amplitudeSubscription?.cancel();
    if (_audioStreamController == null) return;

    _amplitudeSubscription = _audioStreamController!.stream.listen(
      (audioData) {
        final amplitude = _calculateAmplitude(audioData);
        _amplitudeController?.add(amplitude);
      },
      onError: (_) {},
    );
  }

  double _calculateAmplitude(Uint8List audioData) {
    if (audioData.isEmpty) return 0.0;

    final sampleCount = audioData.length ~/ 2;
    if (sampleCount == 0) {
      return 0.0;
    }

    const double minDecibels = -60.0;
    const double maxDecibels = 0.0;

    final dataView = ByteData.sublistView(audioData);
    double sumSquares = 0;

    for (int i = 0; i < sampleCount; i++) {
      final sample = dataView.getInt16(i * 2, Endian.little).toDouble();
      sumSquares += sample * sample;
    }

    final rms = math.sqrt(sumSquares / sampleCount);
    if (rms <= 0) return 0.0;

    final ratio = rms / 32768.0;
    if (ratio <= 0) return 0.0;

    final db = 20 * (math.log(ratio) / math.ln10);
    final clampedDb = db.clamp(minDecibels, maxDecibels);
    final normalized = (clampedDb - minDecibels) / (maxDecibels - minDecibels);
    final percentage = (normalized * 100).clamp(0.0, 100.0);
    return percentage;
  }

  Future<void> stopRecording() async {
    print('⏹️ AudioService: Stopping recording...');
    if (!_isRecording) {
      print('⚠️ AudioService: Not currently recording, skipping');
      return;
    }

    try {
      print('🛑 AudioService: Stopping recorder...');
      await _recorder!.stopRecorder();
      _isRecording = false;
      print('✅ AudioService: Recorder stopped');
      
      print('⏰ AudioService: Cancelling amplitude monitor...');
      if (_amplitudeSubscription != null) {
        await _amplitudeSubscription!.cancel();
        _amplitudeSubscription = null;
      }

      print('📡 AudioService: Closing stream controllers...');
      await _amplitudeController?.close();
      await _audioStreamController?.close();
      _amplitudeController = null;
      _audioStreamController = null;
      print('✅ AudioService: All streams closed');

    } catch (e) {
      print('❌ AudioService: Failed to stop recording: $e');
      throw Exception('Failed to stop recording: $e');
    }
  }

  Future<void> pauseRecording() async {
    if (_isRecording && _recorder != null) {
      await _recorder!.pauseRecorder();
      _amplitudeSubscription?.pause();
    }
  }

  Future<void> resumeRecording() async {
    if (_isRecording && _recorder != null) {
      await _recorder!.resumeRecorder();
      _amplitudeSubscription?.resume();
    }
  }


  void dispose() {
    stopRecording();
    _amplitudeSubscription?.cancel();
    if (_isInitialized && _recorder != null) {
      _recorder!.closeRecorder();
    }
  }
}
