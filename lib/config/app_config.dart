class AppConfig {
  // AssemblyAI API Configuration
  static const String assemblyAIEndpoint = 'wss://streaming.assemblyai.com/v3/ws';
  static const String assemblyAIEUEndpoint = 'wss://streaming.eu.assemblyai.com/v3/ws';
  
  // Audio Configuration
  static const int sampleRate = 16000;
  static const String audioEncoding = 's16le';
  static const int audioChannels = 1;
  static const int audioBitRate = 256000;
  
  // Speech Recognition Configuration
  static const String speechModel = 'universal-streaming-multilingual';
  static const bool enableLanguageDetection = true;
  static const double endOfTurnConfidenceThreshold = 0.4;
  static const int maxTurnSilence = 1280;
  
  // Supported Languages
  static const List<String> supportedLanguages = [
    'en', // English
    'es', // Spanish
    'fr', // French
    'de', // German
    'it', // Italian
    'pt', // Portuguese
  ];
  
  // UI Configuration
  static const int amplitudeVisualizerBars = 30;
  static const double amplitudeVisualizerHeight = 120.0;
  static const Duration amplitudeUpdateInterval = Duration(milliseconds: 50);
  
  // Error Messages
  static const String errorMissingApiKey = 'Please enter your AssemblyAI API key';
  static const String errorConnectionFailed = 'Failed to connect to AssemblyAI';
  static const String errorMicrophonePermission = 'Microphone permission is required';
  static const String errorRecordingFailed = 'Failed to start recording';
  
  // Help URLs
  static const String assemblyAIDashboardUrl = 'https://assemblyai.com/dashboard';
  static const String assemblyAIDocsUrl = 'https://www.assemblyai.com/docs';
  static const String gitHubRepoUrl = 'https://github.com/your-username/assembly_ai_flutter_example';
}