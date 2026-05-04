import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orthodox_chant/features/library/screens/library_screen.dart';

void main() {
  group('LibraryScreen', () {
    testWidgets('shows Kyrie Eleison in the hymn list', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: LibraryScreen()),
        ),
      );
      expect(find.textContaining('Kyrie'), findsOneWidget);
    });

    testWidgets('shows Trisagion in the hymn list', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: LibraryScreen()),
        ),
      );
      expect(find.textContaining('Trisagion'), findsOneWidget);
    });

    testWidgets('tapping a hymn card triggers navigation', (tester) async {
      final routes = <String>[];
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const LibraryScreen(),
            onGenerateRoute: (settings) {
              routes.add(settings.name ?? '');
              return MaterialPageRoute(builder: (_) => const Scaffold());
            },
          ),
        ),
      );
      await tester.tap(find.textContaining('Kyrie').first);
      await tester.pumpAndSettle();
      expect(routes, contains('/lesson'));
    });
  });
}
