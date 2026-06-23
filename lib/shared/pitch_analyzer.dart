import 'dart:math';
import 'dart:typed_data';

import 'package:pitch_detector_dart/pitch_detector.dart';

import '../core/note_utils.dart';

/// One frame's worth of analysis output.
class PitchReading {
  /// Whether the detector considered the frame a clear pitched signal.
  final bool pitched;

  /// Detected fundamental frequency in Hz (meaningful only when [pitched]).
  final double hz;

  /// Detected note name (e.g. "D4"), or null when not [pitched].
  final String? note;

  /// Root-mean-square amplitude of the frame, normalised to 0.0–1.0.
  final double rms;

  const PitchReading({
    required this.pitched,
    required this.hz,
    required this.note,
    required this.rms,
  });
}

/// Pure PCM16 → pitch helper shared by every mic-driven screen.
///
/// Owns a [PitchDetector] and an internal byte buffer. Feed it raw PCM16
/// little-endian bytes from any recorder backend (`record`, `flutter_sound`,
/// or a synthetic buffer in tests) via [addBytes]; it accumulates whole
/// [bufferSize]-sample frames and returns one [PitchReading] per frame.
///
/// This consolidates the buffer-accumulation + RMS + optional-gain +
/// detect loop that was previously copy-pasted in the lesson screen, the
/// diagnostics screen, and [PitchService]. It performs no I/O of its own,
/// which makes it unit-testable.
class PitchAnalyzer {
  PitchAnalyzer({
    this.sampleRate = 44100,
    this.bufferSize = 2048,
    this.gain = 1.0,
  })  : _frameBytes = bufferSize * 2,
        _detector = PitchDetector(
          audioSampleRate: sampleRate.toDouble(),
          bufferSize: bufferSize,
        );

  final int sampleRate;
  final int bufferSize;

  /// Linear amplitude multiplier applied before detection. The lesson screen
  /// uses 4.0 to boost a quiet stream; the default of 1.0 leaves audio as-is.
  final double gain;

  final int _frameBytes; // PCM16 = 2 bytes per sample
  final PitchDetector _detector;
  final List<int> _buffer = [];

  /// Accumulates [bytes] and analyses every complete frame now available.
  /// Usually returns 0 or 1 readings per call, occasionally more.
  Future<List<PitchReading>> addBytes(List<int> bytes) async {
    _buffer.addAll(bytes);
    final readings = <PitchReading>[];

    while (_buffer.length >= _frameBytes) {
      final frame = Uint8List.fromList(_buffer.sublist(0, _frameBytes));
      _buffer.removeRange(0, _frameBytes);

      final samples = frame.buffer.asInt16List();

      var sumSq = 0.0;
      for (final s in samples) {
        sumSq += s * s;
      }
      final rms = sqrt(sumSq / samples.length) / 32768.0;

      final Uint8List toDetect;
      if (gain == 1.0) {
        toDetect = frame;
      } else {
        final amplified = Int16List(samples.length);
        for (var i = 0; i < samples.length; i++) {
          amplified[i] = (samples[i] * gain).clamp(-32768, 32767).toInt();
        }
        toDetect = amplified.buffer.asUint8List();
      }

      final result = await _detector.getPitchFromIntBuffer(toDetect);
      readings.add(PitchReading(
        pitched: result.pitched,
        hz: result.pitch,
        note: result.pitched ? hzToNoteName(result.pitch) : null,
        rms: rms,
      ));
    }

    return readings;
  }

  /// Drops any partially-accumulated frame. Call when (re)starting capture.
  void reset() => _buffer.clear();
}
