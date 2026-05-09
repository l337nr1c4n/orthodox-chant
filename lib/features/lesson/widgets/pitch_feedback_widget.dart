import 'package:flutter/material.dart';
import '../providers/pitch_provider.dart';

class PitchFeedbackWidget extends StatelessWidget {
  final PitchFeedback feedback;

  const PitchFeedbackWidget({super.key, required this.feedback});

  @override
  Widget build(BuildContext context) {
    final (symbol, color) = switch (feedback) {
      PitchFeedback.tooLow => ('↑', Colors.blue),
      PitchFeedback.correct => ('✓', Colors.green),
      PitchFeedback.tooHigh => ('↓', Colors.red),
      PitchFeedback.inactive => ('—', Colors.grey),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      child: Text(
        symbol,
        key: ValueKey(feedback),
        style: TextStyle(fontSize: 64, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
