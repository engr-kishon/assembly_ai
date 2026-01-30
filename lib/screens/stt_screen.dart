import 'dart:async';
import 'package:flutter/material.dart';
import '../services/assembly_ai_service.dart';
import '../services/audio_service.dart';
import '../widgets/amplitude_visualizer.dart';
import '../widgets/transcript_display.dart';

class STTScreen extends StatefulWidget {
  const STTScreen({super.key});

  @override
  State<STTScreen> createState() => _STTScreenState();
}

class _STTScreenState extends State<STTScreen> {
  late AssemblyAIService _assemblyAIService;
  late AudioService _audioService;
  bool _isRecording = false;
  bool _isConnected = false;
  String? _error;
  final TextEditingController _apiKeyController = TextEditingController();

  // Default API key (users should replace this with their own)
  static const String _defaultApiKey = 'YOUR_ASSEMBLY_AI_API_KEY_HERE';

  @override
  void initState() {
    super.initState();
    _assemblyAIService = AssemblyAIService();
    _audioService = AudioService();
    _apiKeyController.text = _defaultApiKey;
    _initializeAudioService();
  }

  Future<void> _initializeAudioService() async {
    try {
      await _audioService.initialize();
    } catch (e) {
      print('Failed to initialize audio service: $e');
    }
  }

  @override
  void dispose() {
    _audioStreamSubscription?.cancel();
    _assemblyAIService.dispose();
    _audioService.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _connectToAssemblyAI() async {
    final apiKey = _apiKeyController.text.trim();
    
    if (apiKey.isEmpty || apiKey == _defaultApiKey) {
      setState(() {
        _error = 'Please enter your AssemblyAI API key';
      });
      return;
    }

    try {
      setState(() {
        _error = null;
      });
      
      await _assemblyAIService.connect(apiKey);
      
      setState(() {
        _isConnected = true;
      });
    } catch (e) {
      String errorMessage = 'Failed to connect to AssemblyAI';
      
      // Provide more helpful error messages
      if (e.toString().contains('402')) {
        errorMessage = 'Payment required. Please upgrade your AssemblyAI account.';
      } else if (e.toString().contains('401') || e.toString().contains('403')) {
        errorMessage = 'Invalid API key. Please check your AssemblyAI API key.';
      } else if (e.toString().contains('429')) {
        errorMessage = 'Rate limit exceeded. Please wait and try again.';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'Network connection failed. Please check your internet connection.';
      }
      
      setState(() {
        _error = errorMessage;
        _isConnected = false;
      });
    }
  }

  Future<void> _disconnectFromAssemblyAI() async {
    await _assemblyAIService.disconnect();
    setState(() {
      _isConnected = false;
    });
  }

  Future<void> _startRecording() async {
    if (!_isConnected) {
      setState(() {
        _error = 'Please connect to AssemblyAI first';
      });
      return;
    }

    try {
      final hasPermission = await _audioService.hasPermission();
      if (!hasPermission) {
        final granted = await _audioService.requestPermissions();
        if (!granted) {
          setState(() {
            _error = 'Microphone permission is required';
          });
          return;
        }
      }

      await _audioService.startRecording();
      _startRealAudioStreaming();
      
      setState(() {
        _isRecording = true;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to start recording: ${e.toString()}';
      });
    }
  }

  StreamSubscription? _audioStreamSubscription;

  void _startRealAudioStreaming() {
    if (_audioService.audioDataStream != null) {
      _audioStreamSubscription = _audioService.audioDataStream!.listen(
        (audioData) {
          if (_isRecording && _isConnected) {
            print('🎵 STTScreen: Received audio chunk - Size: ${audioData.length} bytes');
            print('🎵 STTScreen: First 20 bytes: ${audioData.take(20).toList()}');
            
            _assemblyAIService.sendAudioData(audioData);
          }
        },
        onError: (error) {
          print('❌ STTScreen: Audio stream error: $error');
        },
      );
    }
  }


  Future<void> _stopRecording() async {
    await _audioService.stopRecording();
    
    _audioStreamSubscription?.cancel();
    _audioStreamSubscription = null;
    
    if (_isConnected) {
      _assemblyAIService.terminateSession();
    }
    
    setState(() {
      _isRecording = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AssemblyAI Streaming STT'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(_isConnected ? Icons.cloud_done : Icons.cloud_off),
            onPressed: _isConnected ? _disconnectFromAssemblyAI : _showApiKeyDialog,
            tooltip: _isConnected ? 'Disconnect' : 'Connect to AssemblyAI',
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection Status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            color: _isConnected ? Colors.green[50] : Colors.orange[50],
            child: Row(
              children: [
                Icon(
                  _isConnected ? Icons.check_circle : Icons.warning,
                  color: _isConnected ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  _isConnected 
                    ? 'Connected to AssemblyAI'
                    : 'Not connected - Tap to configure API key',
                  style: TextStyle(
                    color: _isConnected ? Colors.green[800] : Colors.orange[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Error Display
          if (_error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              color: Colors.red[50],
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _error = null),
                  ),
                ],
              ),
            ),

          // Recording Controls
          Container(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Amplitude Visualizer
                if (_isRecording && _audioService.amplitudeStream != null)
                  AmplitudeVisualizer(
                    amplitudeStream: _audioService.amplitudeStream!,
                    color: Colors.blue,
                    height: 120.0,
                  )
                else
                  Container(
                    height: 120.0,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Center(
                      child: Text(
                        'Audio visualization will appear here',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                
                const SizedBox(height: 20),

                // Recording Button
                GestureDetector(
                  onTap: _isRecording ? _stopRecording : _startRecording,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording ? Colors.red : Colors.blue,
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording ? Colors.red : Colors.blue)
                              .withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  _isRecording ? 'Recording...' : 'Tap to start recording',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _isRecording ? Colors.red : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),


          // Language Support Info
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                const Icon(Icons.language, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Supports: English, Spanish, French, German, Italian, Portuguese',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Transcript Display
          Expanded(
            child: _assemblyAIService.transcriptStream != null
                ? TranscriptDisplay(
                    transcriptStream: _assemblyAIService.transcriptStream!,
                  )
                : const Center(
                    child: Text(
                      'Connect to AssemblyAI to see transcripts',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showApiKeyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AssemblyAI API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your AssemblyAI API key to start using real-time transcription:',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                hintText: 'Your AssemblyAI API Key',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            const Text(
              'Get your API key from https://assemblyai.com/dashboard',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _connectToAssemblyAI();
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }
}
