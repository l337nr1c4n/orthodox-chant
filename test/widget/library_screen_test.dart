import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orthodox_chant/features/library/screens/library_screen.dart';

void main() {
  group('LibraryScreen', () {
    testWidgets('renders without crash', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: LibraryScreen()),
        ),
      );
      await tester.pump();
      expect(find.byType(LibraryScreen), findsOneWidget);
    });
  });
}
