import 'package:flutter/material.dart';

class AmplitudeVisualizer extends StatelessWidget {
  final Stream<double> amplitudeStream;
  final Color color;
  final double height;

  const AmplitudeVisualizer({
    super.key,
    required this.amplitudeStream,
    this.color = Colors.blue,
    this.height = 100.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16.0),
      child: StreamBuilder<double>(
        stream: amplitudeStream,
        builder: (context, snapshot) {
          final amplitude = (snapshot.data ?? 0).clamp(0.0, 100.0);
          final displayValue = amplitude.round();
          return Text(
            'Amplitude: $displayValue',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          );
        },
      ),
    );
  }
}
