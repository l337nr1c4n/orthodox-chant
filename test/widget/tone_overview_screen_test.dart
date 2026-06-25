import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orthodox_chant/features/library/widgets/hymn_card.dart';
import 'package:orthodox_chant/features/tones/screens/tone_overview_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Tone 1 overview renders name, preview, character, and hymns',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ToneOverviewScreen(toneId: '1')),
    );
    await tester.pump();

    expect(find.text('Ἦχος Πρῶτος'), findsOneWidget);
    expect(find.text('First Tone'), findsOneWidget);
    expect(find.text('Hear This Tone'), findsOneWidget);
    expect(find.textContaining('First Tone carries'), findsOneWidget);

    // The two Tone 1 hymns are listed.
    expect(find.byType(HymnCard), findsNWidgets(2));
    expect(find.text('Κύριε ἐλέησον'), findsOneWidget);
    expect(find.text('Ἅγιος ὁ Θεός'), findsOneWidget);
  });
}
