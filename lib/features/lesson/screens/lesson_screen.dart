import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:record/record.dart';

import '../../../core/tone_repository.dart';
import '../models/chant_phrase.dart';
import '../providers/audio_provider.dart';
import '../widgets/pitch_track_widget.dart';
import '../../../shared/audio_service.dart';
import '../../../shared/pitch_service.dart';

class LessonScreen extends ConsumerStatefulWidget {
  final String hymnId;

  const LessonScreen({super.key, required this.hymnId});

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  late AudioService _audioService;

  List<ChantPhrase> _phrases = [];
  bool _isLoading = true;

  AudioRecorder? _recorder;
  PitchDetector? _detector;
  final List<int> _pcmBuf = [];
  String? _detectedNote;
  String _micDebug = 'starting...';

  bool _pitchActive = false;
  bool _pitchStarting = false;
  bool _micGranted = false;

  // Watchdog: restarts the stream if no PCM data arrives for 500 ms.
  // This catches Samsung's silent freeze of AudioRecord during playback
  // without triggering a playerState feedback loop.
  Timer? _watchdog;
  int _lastChunkMs = 0;

  @override
  void initState() {
    super.initState();
    _audioService = ref.read(audioServiceProvider);
    _pitchActive = true;
    _load();
    _startPitch();
    _startWatchdog();
  }

  @override
  void dispose() {
    _pitchActive = false;
    _watchdog?.cancel();
    _audioService.stop();
    _recorder?.stop();
    _recorder?.dispose();
    super.dispose();
  }

  void _startWatchdog() {
    _watchdog = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!_pitchActive || !mounted || _pitchStarting || _lastChunkMs == 0) {
        return;
      }
      final silenceMs =
          DateTime.now().millisecondsSinceEpoch - _lastChunkMs;
      if (silenceMs > 500) {
        _restartMic();
      }
    });
  }

  Future<void> _restartMic() async {
    if (!_pitchActive || !mounted) return;
    _pitchStarting = true;
    _lastChunkMs = DateTime.now().millisecondsSinceEpoch; // suppress watchdog during restart
    await _recorder?.stop();
    await _recorder?.dispose();
    _recorder = null;
    _pcmBuf.clear();
    _pitchStarting = false;
    _startPitch();
  }

  void _scheduleRestart() {
    if (!_pitchActive || !mounted || _pitchStarting) return;
    Future.delayed(const Duration(milliseconds: 300), _startPitch);
  }

  Future<void> _load() async {
    final loaded = await loadHymn(widget.hymnId);
    if (!mounted) return;
    setState(() {
      _phrases = loaded.phrases;
      _isLoading = false;
    });
    await _audioService.loadAsset('assets/audio/tone1/${loaded.hymn}.mp3');
  }

  Future<void> _startPitch() async {
    if (!_pitchActive || !mounted || _pitchStarting) return;
    _pitchStarting = true;

    try {
      if (!_micGranted) {
        final status = await Permission.microphone.request();
        if (!mounted || !_pitchActive) return;
        if (!status.isGranted) {
          setState(() => _micDebug = 'mic: permission denied');
          return;
        }
        _micGranted = true;
      }

      await _recorder?.stop();
      await _recorder?.dispose();
      _recorder = null;
      _pcmBuf.clear();

      _recorder = AudioRecorder();
      _detector ??= PitchDetector(audioSampleRate: 44100.0, bufferSize: 2048);

      final stream = await _recorder!.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 44100,
          numChannels: 1,
          androidConfig: AndroidRecordConfig(
            audioSource: AndroidAudioSource.unprocessed,
          ),
        ),
      );

      _lastChunkMs = DateTime.now().millisecondsSinceEpoch; // reset watchdog clock
      if (mounted) setState(() => _micDebug = 'listening');

      const needed = 2048 * 2;
      stream.listen(
        (chunk) async {
          _lastChunkMs = DateTime.now().millisecondsSinceEpoch; // heartbeat
          _pcmBuf.addAll(chunk);
          while (_pcmBuf.length >= needed) {
            final bytes = Uint8List.fromList(_pcmBuf.sublist(0, needed));
            _pcmBuf.removeRange(0, needed);

            final samples = bytes.buffer.asInt16List();
            var sumSq = 0.0;
            for (final s in samples) {
              sumSq += s * s;
            }
            final rms = sqrt(sumSq / samples.length) / 32768.0;

            // 16× software gain: unprocessed mic is ~1–2% RMS raw.
            final amplified = Int16List(samples.length);
            for (int i = 0; i < samples.length; i++) {
              amplified[i] = (samples[i] * 16).clamp(-32768, 32767).toInt();
            }

            final result = await _detector!
                .getPitchFromIntBuffer(amplified.buffer.asUint8List());
            if (mounted) {
              setState(() {
                _detectedNote =
                    result.pitched ? hzToNoteName(result.pitch) : null;
                _micDebug = result.pitched
                    ? '${result.pitch.toStringAsFixed(0)} Hz → ${_detectedNote ?? "?"}'
                    : 'mic ${(rms * 100).toStringAsFixed(1)}%  no pitch';
              });
            }
          }
        },
        onDone: _scheduleRestart,
        onError: (e) {
          if (mounted) setState(() => _micDebug = 'mic error — restarting');
          _scheduleRestart();
        },
      );
    } catch (e) {
      if (mounted) setState(() => _micDebug = 'error: $e');
      _scheduleRestart();
    } finally {
      _pitchStarting = false;
    }
  }

  int _currentIndex(int posMs) {
    if (_phrases.isEmpty) return 0;
    final idx = _phrases.lastIndexWhere((p) => posMs >= p.audioOffsetMs);
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<PlayerState>>(playerStateProvider, (_, next) {
      next.whenData((state) {
        if (state.processingState == ProcessingState.completed) {
          _audioService.seekToStart();
        }
      });
    });

    final position = ref.watch(positionProvider);
    final playerState = ref.watch(playerStateProvider);

    final posMs = (position.valueOrNull ?? Duration.zero).inMilliseconds;
    final currentIdx = _currentIndex(posMs);

    final isPlaying = playerState.when(
      data: (s) => s.playing,
      loading: () => false,
      error: (_, _) => false,
    );

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _audioService.stop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _phrases.isNotEmpty ? _phrases[0].greek : widget.hymnId,
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  const Spacer(),
                  PitchTrackWidget(
                    phrases: _phrases,
                    currentIndex: currentIdx,
                    positionMs: posMs,
                    detectedNote: _detectedNote,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _micDebug,
                    style: TextStyle(
                      color: _detectedNote != null
                          ? const Color(0xFFCFB53B)
                          : Colors.white24,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 48),
                    child: IconButton(
                      iconSize: 64,
                      icon: Icon(
                        isPlaying ? Icons.pause_circle : Icons.play_circle,
                        color: const Color(0xFFCFB53B),
                      ),
                      onPressed: () =>
                          isPlaying ? _audioService.pause() : _audioService.play(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
