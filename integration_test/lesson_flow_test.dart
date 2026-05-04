import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:orthodox_chant/main.dart' as app;
import 'package:orthodox_chant/features/lesson/widgets/pitch_feedback_widget.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Lesson flow', () {
    testWidgets('app launches and LibraryScreen is visible', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      expect(find.textContaining('Kyrie'), findsOneWidget);
    });

    testWidgets('tapping Kyrie navigates to LessonScreen', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Kyrie').first);
      await tester.pumpAndSettle();
      expect(find.byType(PitchFeedbackWidget), findsOneWidget);
    });

    testWidgets('play button tap does not crash', (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Kyrie').first);
      await tester.pumpAndSettle();
      final playButton = find.byIcon(Icons.play_arrow);
      expect(playButton, findsOneWidget);
      await tester.tap(playButton);
      await tester.pump(const Duration(seconds: 1));
      // Verify no exception was thrown by checking the widget tree is still alive
      expect(find.byType(PitchFeedbackWidget), findsOneWidget);
    });
  });
}
