import 'package:flutter/material.dart';
import 'screens/stt_screen.dart';

void main() {
  runApp(const AssemblyAIApp());
}

class AssemblyAIApp extends StatelessWidget {
  const AssemblyAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AssemblyAI Streaming STT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
      ),
      home: const STTScreen(),
    );
  }
}
