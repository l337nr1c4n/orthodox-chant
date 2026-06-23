import 'dart:async';

import 'package:record/record.dart';

import 'pitch_analyzer.dart';

/// Microphone-driven pitch source used by the calibration flow.
///
/// Captures a PCM16 stream via the `record` package and feeds it through a
/// shared [PitchAnalyzer], emitting a detected note name (or null) per frame
/// on [noteStream].
class PitchService {
  static const int _sampleRate = 44100;
  static const int _bufferSize = 2048;

  final PitchAnalyzer _analyzer = PitchAnalyzer(
    sampleRate: _sampleRate,
    bufferSize: _bufferSize,
  );

  AudioRecorder? _recorder;
  StreamController<String?>? _noteController;

  Stream<String?> get noteStream {
    _noteController ??= StreamController<String?>.broadcast();
    return _noteController!.stream;
  }

  Future<void> start() async {
    _noteController ??= StreamController<String?>.broadcast();
    _recorder = AudioRecorder();
    _analyzer.reset();

    try {
      final stream = await _recorder!.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _sampleRate,
          numChannels: 1,
        ),
      );

      stream.listen((chunk) async {
        final readings = await _analyzer.addBytes(chunk);
        for (final r in readings) {
          if (!(_noteController?.isClosed ?? true)) {
            _noteController!.add(r.note);
          }
        }
      });
    } catch (_) {
      // Permission denied or recording unavailable
    }
  }

  Future<void> stop() async {
    await _recorder?.stop();
    await _recorder?.dispose();
    _recorder = null;
    _analyzer.reset();
    await _noteController?.close();
    _noteController = null;
  }
}
