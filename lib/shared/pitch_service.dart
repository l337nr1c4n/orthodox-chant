import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:record/record.dart';

String? hzToNoteName(double hz) {
  if (hz <= 0) return null;
  final midiNote = (12 * (log(hz / 440.0) / log(2)) + 69).round();
  const names = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
  final octave = (midiNote ~/ 12) - 1;
  return '${names[midiNote % 12]}$octave';
}

class PitchService {
  static const int _sampleRate = 44100;
  static const int _bufferSize = 2048;

  final PitchDetector _detector = PitchDetector(
    audioSampleRate: _sampleRate.toDouble(),
    bufferSize: _bufferSize,
  );

  AudioRecorder? _recorder;
  StreamController<String?>? _noteController;
  final List<int> _buffer = [];

  Stream<String?> get noteStream {
    _noteController ??= StreamController<String?>.broadcast();
    return _noteController!.stream;
  }

  Future<void> start() async {
    _noteController ??= StreamController<String?>.broadcast();
    _recorder = AudioRecorder();

    if (!await _recorder!.hasPermission()) return;

    final stream = await _recorder!.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _sampleRate,
        numChannels: 1,
      ),
    );

    // PCM16 = 2 bytes per sample; accumulate until a full buffer is ready
    const needed = _bufferSize * 2;
    stream.listen((chunk) async {
      _buffer.addAll(chunk);
      while (_buffer.length >= needed) {
        final toProcess = Uint8List.fromList(_buffer.sublist(0, needed));
        _buffer.removeRange(0, needed);
        final result = await _detector.getPitchFromIntBuffer(toProcess);
        if (!(_noteController?.isClosed ?? true)) {
          _noteController!.add(result.pitched ? hzToNoteName(result.pitch) : null);
        }
      }
    });
  }

  Future<void> stop() async {
    await _recorder?.stop();
    await _recorder?.dispose();
    _recorder = null;
    _buffer.clear();
    await _noteController?.close();
    _noteController = null;
  }
}
