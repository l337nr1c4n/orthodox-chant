import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orthodox_chant/features/lesson/providers/pitch_provider.dart';
import 'package:orthodox_chant/features/lesson/widgets/pitch_feedback_widget.dart';

Widget _wrap(PitchFeedback feedback) {
  return MaterialApp(
    home: Scaffold(body: PitchFeedbackWidget(feedback: feedback)),
  );
}

void main() {
  group('PitchFeedbackWidget', () {
    testWidgets('shows ↑ when tooLow', (tester) async {
      await tester.pumpWidget(_wrap(PitchFeedback.tooLow));
      expect(find.text('↑'), findsOneWidget);
    });

    testWidgets('shows ✓ when correct', (tester) async {
      await tester.pumpWidget(_wrap(PitchFeedback.correct));
      expect(find.text('✓'), findsOneWidget);
    });

    testWidgets('shows ↓ when tooHigh', (tester) async {
      await tester.pumpWidget(_wrap(PitchFeedback.tooHigh));
      expect(find.text('↓'), findsOneWidget);
    });

    testWidgets('shows — when inactive', (tester) async {
      await tester.pumpWidget(_wrap(PitchFeedback.inactive));
      expect(find.text('—'), findsOneWidget);
    });
  });
}
