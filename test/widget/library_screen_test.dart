import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orthodox_chant/features/library/screens/library_screen.dart';
import 'package:orthodox_chant/features/library/widgets/hymn_card.dart';

void main() {
  group('LibraryScreen', () {
    testWidgets('shows 8 tone cards — Tone 1 available, the rest locked',
        (tester) async {
      // Tall surface so the lazy ListView builds all eight cards at once.
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(home: LibraryScreen()));
      await tester.pump();

      expect(find.byType(HymnCard), findsNWidgets(8));
      // Tones 2–8 are "Coming soon".
      expect(find.text('Coming soon'), findsNWidgets(7));
      // Tone 1's Greek name is shown.
      expect(find.text('Ἦχος Πρῶτος'), findsOneWidget);
    });
  });
}
