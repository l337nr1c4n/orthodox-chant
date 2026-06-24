import 'package:flutter_test/flutter_test.dart';
import 'package:orthodox_chant/core/note_utils.dart';
import 'package:orthodox_chant/features/lesson/models/chant_phrase.dart';
import 'package:orthodox_chant/features/lesson/models/phrase_result.dart';

void main() {
  // A3 = MIDI 57 (the Tone 1 Kyrie centre).
  final targetA3 = noteToMidi('A3')!;

  group('PhraseResult.accuracyOf', () {
    test('all in-tune readings score 1.0', () {
      expect(PhraseResult.accuracyOf(['A3', 'A3', 'A3'], targetA3), 1.0);
    });

    test('readings within one semitone count as hits', () {
      // G#3 (56) and A#3 (58) are both ±1 of A3 (57).
      expect(PhraseResult.accuracyOf(['G#3', 'A#3'], targetA3), 1.0);
    });

    test('readings beyond one semitone are misses', () {
      // B3 (59) is 2 semitones from A3.
      expect(PhraseResult.accuracyOf(['B3'], targetA3), 0.0);
    });

    test('silence / unpitched (null) readings count against the score', () {
      expect(PhraseResult.accuracyOf(['A3', null], targetA3), 0.5);
    });

    test('malformed note names are misses, not crashes', () {
      expect(PhraseResult.accuracyOf(['not-a-note', 'A3'], targetA3), 0.5);
    });

    test('mixed window yields the hit fraction', () {
      // A3 hit, A3 hit, B3 miss, C4 miss -> 2/4.
      expect(
        PhraseResult.accuracyOf(['A3', 'A3', 'B3', 'C4'], targetA3),
        0.5,
      );
    });

    test('empty window is 0.0 (no divide-by-zero)', () {
      expect(PhraseResult.accuracyOf(const [], targetA3), 0.0);
    });
  });

  group('PhraseResult.passed', () {
    const phrase = ChantPhrase(
      greek: 'Κύ',
      transliteration: 'Ky',
      targetNote: 'A3',
      audioOffsetMs: 0,
    );

    test('passes at or above 0.6', () {
      expect(const PhraseResult(phrase: phrase, accuracy: 0.6).passed, isTrue);
      expect(const PhraseResult(phrase: phrase, accuracy: 1.0).passed, isTrue);
    });

    test('fails below 0.6', () {
      expect(const PhraseResult(phrase: phrase, accuracy: 0.59).passed, isFalse);
      expect(const PhraseResult(phrase: phrase, accuracy: 0.0).passed, isFalse);
    });
  });
}
