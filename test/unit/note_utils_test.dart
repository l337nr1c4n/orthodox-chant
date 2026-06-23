import 'package:flutter_test/flutter_test.dart';
import 'package:orthodox_chant/core/note_utils.dart';

void main() {
  group('hzToNoteName', () {
    test('A4 = 440.0 Hz', () => expect(hzToNoteName(440.0), 'A4'));
    test('D4 = 293.66 Hz', () => expect(hzToNoteName(293.66), 'D4'));
    test('E4 = 329.63 Hz', () => expect(hzToNoteName(329.63), 'E4'));
    test('C4 = 261.63 Hz', () => expect(hzToNoteName(261.63), 'C4'));
    test('returns null for 0 Hz', () => expect(hzToNoteName(0.0), isNull));
    test('returns null for negative Hz', () => expect(hzToNoteName(-1.0), isNull));
  });

  group('noteToMidi', () {
    test('A4 = 69', () => expect(noteToMidi('A4'), 69));
    test('C4 = 60 (middle C)', () => expect(noteToMidi('C4'), 60));
    test('D4 = 62', () => expect(noteToMidi('D4'), 62));
    test('sharp: C#4 = 61', () => expect(noteToMidi('C#4'), 61));
    test('negative octave: A-1 = 9', () => expect(noteToMidi('A-1'), 9));
    test('returns null for malformed input', () => expect(noteToMidi('H9'), isNull));
    test('returns null for empty input', () => expect(noteToMidi(''), isNull));
  });

  group('midiToNoteName', () {
    test('69 = A4', () => expect(midiToNoteName(69), 'A4'));
    test('60 = C4', () => expect(midiToNoteName(60), 'C4'));
    test('61 = C#4', () => expect(midiToNoteName(61), 'C#4'));
  });

  group('round-trip', () {
    test('noteToMidi -> midiToNoteName is identity for natural notes', () {
      for (final n in ['G3', 'A3', 'B3', 'C4', 'D4', 'E4', 'F4']) {
        expect(midiToNoteName(noteToMidi(n)!), n);
      }
    });
  });
}
