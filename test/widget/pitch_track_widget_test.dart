import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orthodox_chant/features/lesson/models/chant_phrase.dart';
import 'package:orthodox_chant/features/lesson/widgets/pitch_track_widget.dart';

void main() {
  // Tiny phrase set covering the Kyrie target notes (A3, B3, G3) so the
  // painter has something to draw regardless of offset.
  final phrases = [
    const ChantPhrase(
        greek: 'Κύ', transliteration: 'Ky', targetNote: 'A3', audioOffsetMs: 0),
    const ChantPhrase(
        greek: 'ρι', transliteration: 'ri', targetNote: 'B3', audioOffsetMs: 800),
    const ChantPhrase(
        greek: 'ε', transliteration: 'e', targetNote: 'G3', audioOffsetMs: 1600),
  ];

  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(body: Center(child: child)),
      );

  testWidgets('y-axis labels show the base range when transposeOffset is 0',
      (tester) async {
    await tester.pumpWidget(wrap(PitchTrackWidget(
      phrases: phrases,
      currentIndex: 0,
      positionMs: 0,
      detectedNote: null,
      transposeOffset: 0,
    )));

    // Base window is G3..F4. Endpoints must appear; G2/E3 must not.
    expect(find.text('G3'), findsOneWidget);
    expect(find.text('E4'), findsOneWidget);
    expect(find.text('G2'), findsNothing);
    expect(find.text('E3'), findsNothing);
  });

  testWidgets(
      'y-axis labels shift down one octave when transposeOffset is -12',
      (tester) async {
    await tester.pumpWidget(wrap(PitchTrackWidget(
      phrases: phrases,
      currentIndex: 0,
      positionMs: 0,
      detectedNote: null,
      transposeOffset: -12,
    )));

    // Window shifts to G2..F3. Old endpoints must be gone; shifted labels
    // must appear.
    expect(find.text('G2'), findsOneWidget);
    expect(find.text('E3'), findsOneWidget);
    expect(find.text('G3'), findsNothing);
    expect(find.text('E4'), findsNothing);
  });
}
