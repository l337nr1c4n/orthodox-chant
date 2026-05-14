import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sound/flutter_sound.dart' hide PlayerState;
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';

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

  FlutterSoundRecorder? _recorder;
  StreamController<Uint8List>? _foodController;
  StreamSubscription? _recordingSub;
  PitchDetector? _detector;
  final List<int> _pcmBuf = [];
  String? _detectedNote;
  String _micDebug = 'starting...';

  @override
  void initState() {
    super.initState();
    _audioService = ref.read(audioServiceProvider);
    _init();
  }

  @override
  void dispose() {
    _recordingSub?.cancel();
    _foodController?.close();
    _recorder?.closeRecorder();
    _audioService.stop();
    super.dispose();
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    await session.setActive(true);

    if (!mounted) return;
    await _load();
    await _startPitch();
  }

  Future<void> _load() async {
    final loaded = await loadHymn(widget.hymnId);
    if (!mounted) return;
    setState(() {
      _phrases = loaded.phrases;
      _isLoading = false;
    });
    await _audioService.loadAsset('assets/audio/tone1/${loaded.hymn}.wav');
    await _audioService.setVolume(0.3);
  }

  Future<void> _startPitch() async {
    final status = await Permission.microphone.request();
    if (!mounted) return;
    if (!status.isGranted) {
      setState(() => _micDebug = 'mic: permission denied');
      return;
    }

    _detector = PitchDetector(audioSampleRate: 44100.0, bufferSize: 2048);
    _recorder = FlutterSoundRecorder();

    try {
      await _recorder!.openRecorder();
      if (mounted) setState(() => _micDebug = 'recorder opened');

      _foodController = StreamController<Uint8List>();

      const needed = 2048 * 2;
      _recordingSub = _foodController!.stream.listen((bytes) async {
        _pcmBuf.addAll(bytes);
        while (_pcmBuf.length >= needed) {
          final chunk = Uint8List.fromList(_pcmBuf.sublist(0, needed));
          _pcmBuf.removeRange(0, needed);

          final samples = chunk.buffer.asInt16List();
          var sumSq = 0.0;
          for (final s in samples) {
            sumSq += s * s;
          }
          final rms = sqrt(sumSq / samples.length) / 32768.0;

          // 4× software gain — raw signal is already strong at ~35% RMS
          final amplified = Int16List(samples.length);
          for (int i = 0; i < samples.length; i++) {
            amplified[i] = (samples[i] * 4).clamp(-32768, 32767).toInt();
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
      });

      await _recorder!.startRecorder(
        toStream: _foodController!.sink,
        codec: Codec.pcm16,
        numChannels: 1,
        sampleRate: 44100,
      );

      if (mounted) setState(() => _micDebug = 'listening');
    } catch (e) {
      if (mounted) setState(() => _micDebug = 'error: $e');
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
