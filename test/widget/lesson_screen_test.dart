import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orthodox_chant/features/lesson/providers/audio_provider.dart';
import 'package:orthodox_chant/features/lesson/providers/pitch_provider.dart';
import 'package:orthodox_chant/features/lesson/screens/lesson_screen.dart';
import 'package:orthodox_chant/features/lesson/widgets/pitch_feedback_widget.dart';

void main() {
  group('LessonScreen', () {
    Widget buildSubject() {
      return ProviderScope(
        overrides: [
          positionProvider.overrideWith((_) => Stream.value(Duration.zero)),
          detectedNoteProvider.overrideWith((_) => const Stream.empty()),
          pitchFeedbackProvider.overrideWithValue(PitchFeedback.inactive),
        ],
        child: const MaterialApp(
          home: LessonScreen(hymnId: 'tone1_kyrie'),
        ),
      );
    }

    testWidgets('renders Greek text from Kyrie phrase list', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      expect(find.textContaining('Κύ'), findsOneWidget);
    });

    testWidgets('play button is present', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('PitchFeedbackWidget is in the widget tree', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();
      expect(find.byType(PitchFeedbackWidget), findsOneWidget);
    });
  });
}
