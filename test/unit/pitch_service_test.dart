import 'package:flutter_test/flutter_test.dart';
import 'package:orthodox_chant/shared/pitch_service.dart';

void main() {
  group('hzToNoteName', () {
    test('A4 = 440.0 Hz', () {
      expect(hzToNoteName(440.0), equals('A4'));
    });

    test('D4 = 293.66 Hz', () {
      expect(hzToNoteName(293.66), equals('D4'));
    });

    test('E4 = 329.63 Hz', () {
      expect(hzToNoteName(329.63), equals('E4'));
    });

    test('C4 = 261.63 Hz', () {
      expect(hzToNoteName(261.63), equals('C4'));
    });

    test('returns null for 0 Hz', () {
      expect(hzToNoteName(0.0), isNull);
    });

    test('returns null for negative Hz', () {
      expect(hzToNoteName(-1.0), isNull);
    });
  });
}
