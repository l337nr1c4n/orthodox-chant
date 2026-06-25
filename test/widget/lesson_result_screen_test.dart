import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orthodox_chant/features/lesson/models/chant_phrase.dart';
import 'package:orthodox_chant/features/lesson/models/phrase_result.dart';
import 'package:orthodox_chant/features/lesson/screens/lesson_result_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

PhraseResult _result(String translit, double accuracy) => PhraseResult(
      phrase: ChantPhrase(
        greek: 'x',
        transliteration: translit,
        targetNote: 'A3',
        audioOffsetMs: 0,
      ),
      accuracy: accuracy,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('LessonResultScreen.starsFor', () {
    test('all phrases passed → 3 stars', () {
      expect(LessonResultScreen.starsFor([_result('a', 0.8), _result('b', 1.0)]),
          3);
    });

    test('at least 60% passed → 2 stars', () {
      // 3 of 5 pass = 0.6 exactly.
      final results = [
        _result('a', 0.6),
        _result('b', 0.7),
        _result('c', 0.9),
        _result('d', 0.1),
        _result('e', 0.0),
      ];
      expect(LessonResultScreen.starsFor(results), 2);
    });

    test('attempted but below 60% → 1 star', () {
      final results = [_result('a', 0.6), _result('b', 0.0), _result('c', 0.0)];
      expect(LessonResultScreen.starsFor(results), 1);
    });

    test('no results → 0 stars', () {
      expect(LessonResultScreen.starsFor(const []), 0);
    });
  });

  group('LessonResultScreen rendering', () {
    testWidgets('shows the right stars, headline, rows, and actions',
        (tester) async {
      final results = [
        _result('Ky', 0.9), // pass
        _result('ri', 0.7), // pass
        _result('e', 0.2), // fail
      ]; // 2 of 3 → 2 stars

      await tester.pumpWidget(
        MaterialApp(
          home: LessonResultScreen(hymnId: 'tone1_kyrie', results: results),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.star_rounded), findsNWidgets(2));
      expect(find.byIcon(Icons.star_outline_rounded), findsOneWidget);
      expect(find.text('2 of 3 phrases matched'), findsOneWidget);
      expect(find.text('Ky'), findsOneWidget);
      expect(find.text('ri'), findsOneWidget);
      expect(find.text('e'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.text('Back to Hymns'), findsOneWidget);
    });

    testWidgets('Try Again pops with ResultAction.tryAgain', (tester) async {
      ResultAction? popped;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                popped = await Navigator.of(context).push<ResultAction>(
                  MaterialPageRoute(
                    builder: (_) => LessonResultScreen(
                      hymnId: 'tone1_kyrie',
                      results: [_result('Ky', 0.9)],
                    ),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();

      expect(popped, ResultAction.tryAgain);
    });
  });
}
