import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';

class AssemblyAIService {
  static const String _baseUrl = 'wss://streaming.assemblyai.com/v3/ws';
  static const int _sampleRate = 16000;

  WebSocketChannel? _channel;
  final StreamController<TranscriptEvent> _events =
      StreamController<TranscriptEvent>.broadcast();

  bool _isConnected = false;

  final BytesBuilder _audioBuffer = BytesBuilder(copy: false);
  Timer? _silenceTimer;
  DateTime _lastAudioSent = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime? _connectionStartTime;

  // Target chunk size: 100ms at 16kHz = 1600 samples * 2 bytes = 3200 bytes
  int get _targetChunkBytes => (_sampleRate / 10).round() * 2;

  Stream<TranscriptEvent> get events => _events.stream;

  Stream<TranscriptResponse> get transcriptStream => _events.stream
      .where((event) => event.transcript != null)
      .map((event) => event.transcript!);
  bool get isConnected => _isConnected;

  Future<void> connect(String apiKey) async {
    final uri = Uri.parse(
      '$_baseUrl'
          '?token=$apiKey'
          '&sample_rate=$_sampleRate'
          '&encoding=pcm_s16le'
          '&format_turns=false'
          '&format_text=true'
          '&punctuate=true'
          '&inactivity_timeout=60'
          '&speech_model=universal-streaming-multilingual'
          '&language_detection=true',
    );

    print('🔗 AssemblyAI: Connecting to: $uri');

    try {
      // Prefer header auth. token query param sometimes works, but header is safer.
      _channel = WebSocketChannel.connect(uri);

      _connectionStartTime = DateTime.now();
      _isConnected = true;

      print('✅ AssemblyAI: Connected at ${_connectionStartTime!.toIso8601String()}');

      _channel!.stream.listen(
        _handleMessage,
        onError: (e) => _handleError(e),
        onDone: () => _handleDisconnection(),
        cancelOnError: true,
      );

      // Optional keepalive (only if your mic stops producing bytes during silence)
      // _startSilenceKeepAlive();
    } catch (e) {
      _isConnected = false;
      _publishError(
        code: null,
        message: 'Failed to connect: $e',
        raw: e.toString(),
      );
      rethrow;
    }
  }

  /// Send PCM16LE audio bytes. v3 expects BINARY frames.
  void sendAudioData(Uint8List audioBytes) {
    if (!_isConnected || _channel == null) {
      print('🔴 AssemblyAI: Not connected, cannot send audio.');
      return;
    }

    _audioBuffer.add(audioBytes);

    // Send fixed-size chunks (good for realtime stability)
    while (_audioBuffer.length >= _targetChunkBytes) {
      final allBytes = _audioBuffer.takeBytes();
      final chunk = allBytes.sublist(0, _targetChunkBytes);
      final remaining = allBytes.sublist(_targetChunkBytes);

      if (remaining.isNotEmpty) _audioBuffer.add(remaining);

      _sendAudioChunk(Uint8List.fromList(chunk));
    }
  }

  void _sendAudioChunk(Uint8List chunk) {
    try {
      // ✅ IMPORTANT: send binary bytes, NOT base64, NOT JSON
      _channel!.sink.add(chunk);
      _lastAudioSent = DateTime.now();
      // print('📤 AssemblyAI: Sent ${chunk.length} bytes');
    } catch (e) {
      _handleError(e);
    }
  }

  void _startSilenceKeepAlive() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!_isConnected || _channel == null) {
        timer.cancel();
        return;
      }

      final idleMs = DateTime.now().difference(_lastAudioSent).inMilliseconds;
      if (idleMs > 400) {
        final silence = Uint8List(_targetChunkBytes); // zeroed PCM
        print('🔇 AssemblyAI: Sending silence keepalive (${silence.length} bytes)');
        _sendAudioChunk(silence);
      }
    });
    print('⏰ AssemblyAI: Silence keepalive started');
  }

  void terminateSession() {
    if (_channel != null) {
      try {
        _channel!.sink.close();
      } catch (_) {}
    }
  }

  void _handleMessage(dynamic message) {
    if (message is! String) {
      // Server messages are JSON strings. If you get bytes here, just log.
      print('⚠️ AssemblyAI: Non-string message from server: ${message.runtimeType}');
      return;
    }

    // print('📨 AssemblyAI: $message');
    try {
      final data = jsonDecode(message) as Map<String, dynamic>;
      final type = data['type'];

      if (type == 'Begin') {
        print('🎬 AssemblyAI: Session Begin');
        _emitEvent(TranscriptEvent.status('begin'));
        return;
      }

      if (type == 'Turn') {
        final transcript = (data['transcript'] ?? '') as String;
        final endOfTurn = (data['end_of_turn'] ?? false) as bool;

        if (transcript.isNotEmpty) {
          _emitEvent(TranscriptEvent.transcript(
            TranscriptResponse.fromV3Json(data),
          ));
        }

        // Optional: you can also emit partials even if transcript empty,
        // but usually not needed.
        return;
      }

      if (type == 'Termination') {
        print('🔚 AssemblyAI: Server Termination');
        _emitEvent(TranscriptEvent.status('termination'));
        return;
      }

      // Some errors come as JSON too
      if (type == 'Error' || data.containsKey('error')) {
        _publishError(
          code: data['code'],
          message: data['message']?.toString() ?? 'AssemblyAI Error',
          raw: message,
        );
        return;
      }

      // Unknown message types: keep as debug
      print('ℹ️ AssemblyAI: Unhandled message type: $type');
    } catch (e) {
      // If parsing fails, publish it as an error
      _publishError(
        code: null,
        message: 'Failed to parse server message: $e',
        raw: message,
      );
    }
  }

  void _handleError(Object error) {
    // web_socket_channel often wraps close codes/errors in exceptions or strings.
    final raw = error.toString();
    final code = _extractCloseCode(raw);

    print('❌ AssemblyAI: WebSocket error: $raw');
    _publishError(
      code: code,
      message: _friendlyWsErrorMessage(code, raw),
      raw: raw,
    );

    _isConnected = false;
  }

  void _handleDisconnection() {
    final now = DateTime.now();
    final seconds = _connectionStartTime == null
        ? 0
        : now.difference(_connectionStartTime!).inSeconds;

    print('🔌 AssemblyAI: Disconnected after ${seconds}s');

    // Publish a disconnect event (useful for UI)
    _emitEvent(TranscriptEvent.disconnected(
      durationSeconds: seconds,
      message: seconds < 5
          ? 'Disconnected quickly — check API key / query params / audio format.'
          : 'Disconnected.',
    ));

    _isConnected = false;
  }

  Future<void> disconnect() async {
    final now = DateTime.now();
    final seconds = _connectionStartTime == null
        ? 0
        : now.difference(_connectionStartTime!).inSeconds;

    print('🔌 AssemblyAI: Manual disconnect after ${seconds}s');

    _silenceTimer?.cancel();
    _silenceTimer = null;

    _audioBuffer.clear();

    try {
      await _channel?.sink.close();
    } catch (_) {}

    _channel = null;
    _isConnected = false;
    _connectionStartTime = null;

    print('✅ AssemblyAI: Disconnected cleanly');
  }

  void dispose() {
    disconnect();
    _events.close();
  }

  // ---------- Helpers ----------

  void _publishError({
    required Object? code,
    required String message,
    required String raw,
  }) {
    _emitEvent(TranscriptEvent.error(
      code: code?.toString(),
      message: message,
      raw: raw,
    ));
  }

  void _emitEvent(TranscriptEvent event) {
    if (_events.isClosed) return;
    _events.add(event);
  }

  /// Attempts to extract a close code like "3005" from error strings.
  int? _extractCloseCode(String raw) {
    final m = RegExp(r'\b(3\d{3}|1\d{3}|2\d{3}|4\d{3})\b').firstMatch(raw);
    if (m == null) return null;
    return int.tryParse(m.group(1)!);
  }

  String _friendlyWsErrorMessage(int? code, String raw) {
    // Common patterns you hit:
    if (code == 3005) {
      // In your logs: 3005 + "Invalid JSON" or "Invalid Message Type"
      return 'Server rejected the message format. For v3, send BINARY PCM16 bytes (Uint8List) — not base64 and not JSON.';
    }
    if (raw.contains('401') || raw.contains('403')) {
      return 'Authentication failed. Check your API key / token.';
    }
    if (raw.contains('429')) {
      return 'Rate limit exceeded. Try again later or reduce connections.';
    }
    if (raw.contains('SocketException')) {
      return 'Network error. Check your internet connection.';
    }
    if (raw.contains('TimeoutException')) {
      return 'Connection timed out.';
    }
    return 'WebSocket error: $raw';
  }
}

// ===================== Events =====================

class TranscriptEvent {
  final TranscriptResponse? transcript;
  final TranscriptError? error;
  final TranscriptDisconnect? disconnect;
  final String? status;

  TranscriptEvent._({
    this.transcript,
    this.error,
    this.disconnect,
    this.status,
  });

  factory TranscriptEvent.transcript(TranscriptResponse t) =>
      TranscriptEvent._(transcript: t);

  factory TranscriptEvent.error({
    required String? code,
    required String message,
    required String raw,
  }) =>
      TranscriptEvent._(error: TranscriptError(code: code, message: message, raw: raw));

  factory TranscriptEvent.disconnected({
    required int durationSeconds,
    required String message,
  }) =>
      TranscriptEvent._(
        disconnect: TranscriptDisconnect(durationSeconds: durationSeconds, message: message),
      );

  factory TranscriptEvent.status(String status) => TranscriptEvent._(status: status);
}

class TranscriptError {
  final String? code;
  final String message;
  final String raw;

  TranscriptError({
    required this.code,
    required this.message,
    required this.raw,
  });

  @override
  String toString() => 'TranscriptError(code: $code, message: $message)';
}

class TranscriptDisconnect {
  final int durationSeconds;
  final String message;

  TranscriptDisconnect({
    required this.durationSeconds,
    required this.message,
  });

  @override
  String toString() => 'TranscriptDisconnect(duration: ${durationSeconds}s, message: $message)';
}

// ===================== Transcript Models =====================

class TranscriptResponse {
  final String type;
  final String text;
  final double? confidence;
  final List<Word>? words;
  final bool isFinal;

  TranscriptResponse({
    required this.type,
    required this.text,
    this.confidence,
    this.words,
    required this.isFinal,
  });

  factory TranscriptResponse.fromV3Json(Map<String, dynamic> json) {
    List<Word>? wordList;
    if (json['words'] != null) {
      wordList = (json['words'] as List)
          .map((w) => Word.fromJson(w as Map<String, dynamic>))
          .toList();
    }

    double? avgConfidence;
    if (wordList != null && wordList.isNotEmpty) {
      final sum = wordList.fold<double>(0.0, (s, w) => s + w.confidence);
      avgConfidence = sum / wordList.length;
    }

    final endOfTurn = (json['end_of_turn'] ?? false) as bool;

    return TranscriptResponse(
      type: (json['type'] ?? '').toString(),
      text: (json['transcript'] ?? '').toString(),
      confidence: avgConfidence,
      words: wordList,
      isFinal: endOfTurn,
    );
  }

  @override
  String toString() => 'TranscriptResponse(text: $text, isFinal: $isFinal, confidence: $confidence)';
}

class Word {
  final String text;
  final int start;
  final int end;
  final double confidence;

  Word({
    required this.text,
    required this.start,
    required this.end,
    required this.confidence,
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      text: (json['text'] ?? '').toString(),
      start: (json['start'] ?? 0) as int,
      end: (json['end'] ?? 0) as int,
      confidence: (json['confidence'] is num) ? (json['confidence'] as num).toDouble() : 0.0,
    );
  }
}
