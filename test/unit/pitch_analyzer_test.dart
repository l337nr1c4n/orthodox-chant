import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:orthodox_chant/shared/pitch_analyzer.dart';

/// Builds [samples] of a PCM16 little-endian sine wave at [hz].
List<int> _sinePcm16(
  double hz, {
  int samples = 2048,
  int sampleRate = 44100,
  double amp = 0.6,
}) {
  final out = Uint8List(samples * 2);
  for (var i = 0; i < samples; i++) {
    final v = (sin(2 * pi * hz * i / sampleRate) * amp * 32767)
        .round()
        .clamp(-32768, 32767);
    out[i * 2] = v & 0xFF;
    out[i * 2 + 1] = (v >> 8) & 0xFF;
  }
  return out;
}

void main() {
  group('PitchAnalyzer', () {
    test('detects a clean 440 Hz sine as A4', () async {
      final analyzer = PitchAnalyzer();
      final readings = await analyzer.addBytes(_sinePcm16(440));
      expect(readings, isNotEmpty);
      expect(readings.first.pitched, isTrue);
      expect(readings.first.hz, closeTo(440, 10));
      expect(readings.first.note, 'A4');
    });

    test('silence is not pitched and has zero RMS', () async {
      final analyzer = PitchAnalyzer();
      final readings = await analyzer.addBytes(List.filled(2048 * 2, 0));
      expect(readings, isNotEmpty);
      expect(readings.first.pitched, isFalse);
      expect(readings.first.note, isNull);
      expect(readings.first.rms, 0.0);
    });

    test('buffers partial frames until a full frame is available', () async {
      final analyzer = PitchAnalyzer();
      // Half a frame (2048 of the needed 4096 bytes) → nothing yet.
      expect(await analyzer.addBytes(List.filled(2048, 0)), isEmpty);
      // The remaining half completes one frame → one reading.
      expect(await analyzer.addBytes(List.filled(2048, 0)), hasLength(1));
    });

    test('reported RMS reflects raw input level, independent of gain', () async {
      // Gain only boosts the detection buffer; the reported RMS stays the
      // raw input level so the diagnostics meter shows true signal strength.
      final quiet = _sinePcm16(440, amp: 0.1);
      final plain = await PitchAnalyzer().addBytes(quiet);
      final boosted = await PitchAnalyzer(gain: 4).addBytes(quiet);
      expect(boosted.first.rms, closeTo(plain.first.rms, 1e-9));
      expect(boosted.first.note, 'A4');
    });
  });
}
