import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:record/record.dart';

import '../../shared/pitch_service.dart';

class PitchTestScreen extends StatefulWidget {
  const PitchTestScreen({super.key});

  @override
  State<PitchTestScreen> createState() => _PitchTestScreenState();
}

class _PitchTestScreenState extends State<PitchTestScreen> {
  static const _sampleRate = 44100;
  static const _bufferSize = 2048;

  final _recorder = AudioRecorder();
  final _detector = PitchDetector(
    audioSampleRate: _sampleRate.toDouble(),
    bufferSize: _bufferSize,
  );
  final List<int> _buf = [];

  bool _micGranted = false;
  bool _running = false;
  bool _pitched = false;
  double _hz = 0;
  double _amplitude = 0;
  String? _note;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final status = await Permission.microphone.request();
    if (!mounted) return;
    if (!status.isGranted) {
      setState(() => _micGranted = false);
      return;
    }
    setState(() => _micGranted = true);

    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _sampleRate,
        numChannels: 1,
      ),
    );
    if (!mounted) return;
    setState(() => _running = true);

    const needed = _bufferSize * 2; // bytes for 2048 int16 samples
    stream.listen((chunk) async {
      _buf.addAll(chunk);
      while (_buf.length >= needed) {
        final bytes = Uint8List.fromList(_buf.sublist(0, needed));
        _buf.removeRange(0, needed);

        // RMS amplitude — tells us if the mic is picking up sound at all
        final samples = bytes.buffer.asInt16List();
        var sumSq = 0.0;
        for (final s in samples) {
          sumSq += s * s;
        }
        final rms = sqrt(sumSq / samples.length) / 32768.0;

        final result = await _detector.getPitchFromIntBuffer(bytes);

        if (mounted) {
          setState(() {
            _amplitude = rms;
            _pitched = result.pitched;
            _hz = result.pitch;
            _note = result.pitched ? hzToNoteName(result.pitch) : null;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _recorder.stop();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFCFB53B);
    final ampPct = (_amplitude * 100).clamp(0.0, 100.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pitch Detection Test'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mic / running status
            _StatusRow(
              label: 'Microphone',
              value: !_micGranted
                  ? 'Permission denied'
                  : _running
                      ? 'Active'
                      : 'Starting...',
              color: _running ? Colors.greenAccent : Colors.redAccent,
            ),
            const SizedBox(height: 24),

            // Amplitude meter — if this is 0, the mic isn't capturing audio
            const Text(
              'Input level',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _amplitude * 4, // scale so normal speech ≈ 50%
                minHeight: 20,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation(
                  _amplitude > 0.005 ? Colors.greenAccent : Colors.white24,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${ampPct.toStringAsFixed(1)} %  '
              '(speak or sing — this should move)',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 32),

            // Pitch detection result
            _StatusRow(
              label: 'Pitched signal',
              value: _pitched ? 'YES' : 'no',
              color: _pitched ? Colors.greenAccent : Colors.white38,
            ),
            const SizedBox(height: 12),
            _StatusRow(
              label: 'Frequency',
              value: _hz > 0 ? '${_hz.toStringAsFixed(1)} Hz' : '—',
              color: Colors.white70,
            ),
            const SizedBox(height: 32),

            // Big detected note
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 100),
                child: Text(
                  _note ?? '—',
                  key: ValueKey(_note),
                  style: TextStyle(
                    fontSize: 96,
                    fontWeight: FontWeight.bold,
                    color: _note != null ? gold : Colors.white24,
                  ),
                ),
              ),
            ),

            const Spacer(),
            const Text(
              'Sing a steady note into the phone.\n'
              '• Input level should rise when you make any sound.\n'
              '• "Pitched signal: YES" appears when the note is clear.\n'
              '• The large letter is the detected note name.',
              style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.6),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatusRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 16)),
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
