import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orthodox_chant/features/lesson/screens/lesson_screen.dart';

void main() {
  group('LessonScreen', () {
    testWidgets('renders without crash', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LessonScreen(hymnId: 'tone1_kyrie'),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(LessonScreen), findsOneWidget);
    });
  });
}
