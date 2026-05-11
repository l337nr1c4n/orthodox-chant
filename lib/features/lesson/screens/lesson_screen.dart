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
import '../../../shared/pitch_service.dart';

class LessonScreen extends ConsumerStatefulWidget {
  final String hymnId;

  const LessonScreen({super.key, required this.hymnId});

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  // Hymn content
  List<ChantPhrase> _phrases = [];
  bool _isLoading = true;

  // Pitch detection — direct (same approach as PitchTestScreen)
  AudioRecorder? _recorder;
  PitchDetector? _detector;
  final List<int> _pcmBuf = [];
  String? _detectedNote;
  String _micDebug = 'starting...';

  @override
  void initState() {
    super.initState();
    _load();
    _startPitch();
  }

  @override
  void dispose() {
    ref.read(audioServiceProvider).stop();
    _recorder?.stop();
    _recorder?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final loaded = await loadHymn(widget.hymnId);
    if (!mounted) return;
    setState(() {
      _phrases = loaded.phrases;
      _isLoading = false;
    });
    await ref
        .read(audioServiceProvider)
        .loadAsset('assets/audio/tone1/${loaded.hymn}.mp3');
  }

  Future<void> _startPitch() async {
    final status = await Permission.microphone.request();
    if (!mounted) return;
    if (!status.isGranted) {
      setState(() => _micDebug = 'permission denied');
      return;
    }

    _recorder = AudioRecorder();
    _detector = PitchDetector(audioSampleRate: 44100.0, bufferSize: 2048);

    try {
      final stream = await _recorder!.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 44100,
          numChannels: 1,
          // Disable Android AEC — it suppresses voice when speaker is active
          androidConfig: AndroidRecordConfig(
            audioSource: AndroidAudioSource.voicePerformance,
          ),
        ),
      );
      if (mounted) setState(() => _micDebug = 'listening');

      const needed = 2048 * 2;
      stream.listen((chunk) async {
        _pcmBuf.addAll(chunk);
        while (_pcmBuf.length >= needed) {
          final bytes = Uint8List.fromList(_pcmBuf.sublist(0, needed));
          _pcmBuf.removeRange(0, needed);
          final result = await _detector!.getPitchFromIntBuffer(bytes);
          if (mounted) {
            setState(() {
              _detectedNote =
                  result.pitched ? hzToNoteName(result.pitch) : null;
              _micDebug = result.pitched
                  ? '${result.pitch.toStringAsFixed(0)} Hz → ${_detectedNote ?? "?"}'
                  : 'listening';
            });
          }
        }
      });
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
    // Seek back to start when playback finishes
    ref.listen<AsyncValue<PlayerState>>(playerStateProvider, (_, next) {
      next.whenData((state) {
        if (state.processingState == ProcessingState.completed) {
          ref.read(audioServiceProvider).seekToStart();
        }
      });
    });

    final position = ref.watch(positionProvider);
    final audioService = ref.watch(audioServiceProvider);
    final playerState = ref.watch(playerStateProvider);

    final posMs =
        (position.valueOrNull ?? Duration.zero).inMilliseconds;
    final currentIdx = _currentIndex(posMs);

    final isPlaying = playerState.when(
      data: (s) => s.playing,
      loading: () => false,
      error: (_, _) => false,
    );

    return Scaffold(
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
                        isPlaying ? audioService.pause() : audioService.play(),
                  ),
                ),
              ],
            ),
    );
  }
}
