import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orthodox_chant/features/lesson/providers/pitch_provider.dart';
import 'package:orthodox_chant/features/lesson/widgets/pitch_feedback_widget.dart';

Widget _wrap(Widget child, PitchFeedback feedback) {
  return ProviderScope(
    overrides: [
      pitchFeedbackProvider.overrideWithValue(feedback),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  group('PitchFeedbackWidget', () {
    testWidgets('shows ↑ when tooLow', (tester) async {
      await tester.pumpWidget(_wrap(const PitchFeedbackWidget(), PitchFeedback.tooLow));
      expect(find.text('↑'), findsOneWidget);
    });

    testWidgets('shows ✓ when correct', (tester) async {
      await tester.pumpWidget(_wrap(const PitchFeedbackWidget(), PitchFeedback.correct));
      expect(find.text('✓'), findsOneWidget);
    });

    testWidgets('shows ↓ when tooHigh', (tester) async {
      await tester.pumpWidget(_wrap(const PitchFeedbackWidget(), PitchFeedback.tooHigh));
      expect(find.text('↓'), findsOneWidget);
    });

    testWidgets('shows — when inactive', (tester) async {
      await tester.pumpWidget(_wrap(const PitchFeedbackWidget(), PitchFeedback.inactive));
      expect(find.text('—'), findsOneWidget);
    });
  });
}
