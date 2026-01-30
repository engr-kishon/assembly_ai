import 'package:flutter/material.dart';
import '../services/assembly_ai_service.dart';

class TranscriptDisplay extends StatefulWidget {
  final Stream<TranscriptResponse> transcriptStream;

  const TranscriptDisplay({
    super.key,
    required this.transcriptStream,
  });

  @override
  State<TranscriptDisplay> createState() => _TranscriptDisplayState();
}

class _TranscriptDisplayState extends State<TranscriptDisplay> {
  final List<String> _finalSegments = [];
  String _partialTranscript = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    widget.transcriptStream.listen(
      (transcript) {
        setState(() {
          final text = transcript.text.trim();
          if (transcript.isFinal) {
            final formatted = _formatSegment(text, ensureTerminalPunctuation: true);
            if (formatted.isNotEmpty) {
              _finalSegments.add(formatted);
            }
            _partialTranscript = '';
          } else {
            _partialTranscript = _formatSegment(text);
          }
        });
        _scrollToBottom();
      },
      onError: (error) {
        print('❌ TranscriptDisplay: Stream error: $error');
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasTranscript = _finalSegments.isNotEmpty || _partialTranscript.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.book, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Live Transcript',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _clearTranscripts,
                tooltip: 'Clear transcripts',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: hasTranscript ? _buildParagraphView() : _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mic_none,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Start speaking to see live transcription',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildParagraphView() {
    final segments = [
      if (_finalSegments.isNotEmpty) _finalSegments.join(' '),
      if (_partialTranscript.isNotEmpty) _partialTranscript,
    ];
    final paragraphText = segments.where((s) => s.isNotEmpty).join(' ').trim();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Scrollbar(
        controller: _scrollController,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(12.0),
          child: Text(
            paragraphText,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  void _clearTranscripts() {
    setState(() {
      _finalSegments.clear();
      _partialTranscript = '';
    });
  }

  String _formatSegment(
    String text, {
    bool ensureTerminalPunctuation = false,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '';

    final buffer = StringBuffer();
    bool capitalizeNext = true;

    for (final rune in trimmed.runes) {
      final char = String.fromCharCode(rune);

      if (capitalizeNext && _isAlphabetic(char)) {
        buffer.write(char.toUpperCase());
        capitalizeNext = false;
      } else {
        buffer.write(char);
      }

      if (_isSentenceTerminator(char)) {
        capitalizeNext = true;
      } else if (!_isWhitespace(char)) {
        capitalizeNext = false;
      }
    }

    var formatted = buffer.toString().trim();
    if (ensureTerminalPunctuation &&
        formatted.isNotEmpty &&
        !_isSentenceTerminator(formatted[formatted.length - 1])) {
      formatted = '$formatted.';
    }
    return formatted;
  }

  bool _isAlphabetic(String char) {
    if (char.isEmpty) return false;
    final code = char.codeUnitAt(0);
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
  }

  bool _isWhitespace(String char) => char.trim().isEmpty;

  bool _isSentenceTerminator(String char) => char == '.' || char == '!' || char == '?';
}
