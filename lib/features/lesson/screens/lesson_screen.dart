import 'dart:async';
import 'dart:typed_data';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sound/flutter_sound.dart' hide PlayerState;
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/tone_repository.dart';
import '../models/chant_phrase.dart';
import '../providers/audio_provider.dart';
import '../providers/voice_range_provider.dart';
import '../widgets/pitch_track_widget.dart';
import '../../../shared/audio_service.dart';
import '../../../shared/pitch_analyzer.dart';

const Color _gold = Color(0xFFCFB53B);

/// A lesson runs in two explicit phases:
/// - [listen]: the reference audio plays and the track scrolls. No mic.
/// - [sing]: the mic is live and the user sings. Entered only on "Sing It".
enum LessonPhase { listen, sing }

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

  LessonPhase _phase = LessonPhase.listen;

  FlutterSoundRecorder? _recorder;
  StreamController<Uint8List>? _foodController;
  StreamSubscription? _recordingSub;
  Timer? _phraseTimer; // populated by the per-phrase scoring window (ORT-44)
  final PitchAnalyzer _analyzer = PitchAnalyzer(gain: 4);
  String? _detectedNote;
  String _micDebug = '';

  @override
  void initState() {
    super.initState();
    _audioService = ref.read(audioServiceProvider);
    _load();
  }

  @override
  void dispose() {
    _phraseTimer?.cancel();
    _recordingSub?.cancel();
    _foodController?.close();
    _recorder?.closeRecorder();
    _audioService.stop();
    super.dispose();
  }

  /// Configures a playAndRecord audio session. Deferred to the Sing phase so
  /// it never blocks Listen-phase load (it previously stalled lesson open).
  Future<void> _configureRecordingSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.defaultToSpeaker,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ));
    } catch (_) {}
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

  /// Enters the Sing phase: requests the mic, opens the recorder, and starts
  /// streaming PCM into the shared analyzer. The reference audio is paused —
  /// this is the user's turn to sing.
  Future<void> _enterSingPhase() async {
    final status = await Permission.microphone.request();
    if (!mounted) return;
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission is needed to sing.'),
        ),
      );
      return;
    }

    await _audioService.pause();
    await _configureRecordingSession();

    _recorder = FlutterSoundRecorder();
    try {
      await _recorder!.openRecorder();
      _foodController = StreamController<Uint8List>();

      // 4× software gain lives in the analyzer (raw stream is quiet on-device).
      _recordingSub = _foodController!.stream.listen((bytes) async {
        final readings = await _analyzer.addBytes(bytes);
        if (readings.isEmpty || !mounted) return;
        final r = readings.last;
        setState(() {
          _detectedNote = r.note;
          _micDebug = r.pitched
              ? '${r.hz.toStringAsFixed(0)} Hz → ${r.note ?? "?"}'
              : 'mic ${(r.rms * 100).toStringAsFixed(1)}%  no pitch';
        });
      });

      await _recorder!.startRecorder(
        toStream: _foodController!.sink,
        codec: Codec.pcm16,
        numChannels: 1,
        sampleRate: 44100,
      );

      if (!mounted) return;
      setState(() {
        _phase = LessonPhase.sing;
        _micDebug = 'listening';
      });
    } catch (e) {
      if (mounted) setState(() => _micDebug = 'error: $e');
    }
  }

  /// Returns to the Listen phase: tears the mic down and cancels any
  /// in-flight phrase timers.
  Future<void> _exitSingPhase() async {
    await _stopMic();
    if (!mounted) return;
    setState(() {
      _phase = LessonPhase.listen;
      _detectedNote = null;
      _micDebug = '';
    });
  }

  Future<void> _stopMic() async {
    _phraseTimer?.cancel();
    _phraseTimer = null;
    await _recordingSub?.cancel();
    _recordingSub = null;
    await _foodController?.close();
    _foodController = null;
    await _recorder?.stopRecorder();
    await _recorder?.closeRecorder();
    _recorder = null;
    _analyzer.reset();
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
    final transposeOffset = ref.watch(voiceOffsetProvider).valueOrNull ?? 0;

    final posMs = (position.valueOrNull ?? Duration.zero).inMilliseconds;
    final currentIdx = _currentIndex(posMs);

    final isPlaying = playerState.when(
      data: (s) => s.playing,
      loading: () => false,
      error: (_, _) => false,
    );

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _stopMic();
          _audioService.stop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _phrases.isNotEmpty ? _phrases[0].greek : widget.hymnId,
          ),
          centerTitle: true,
          bottom: _appBarBanner(transposeOffset),
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
                    transposeOffset: transposeOffset,
                  ),
                  const SizedBox(height: 8),
                  if (_phase == LessonPhase.sing)
                    Text(
                      _micDebug,
                      style: TextStyle(
                        color: _detectedNote != null ? _gold : Colors.white24,
                        fontSize: 12,
                      ),
                    ),
                  const Spacer(),
                  _phase == LessonPhase.listen
                      ? _buildListenControls(isPlaying)
                      : _buildSingControls(),
                ],
              ),
      ),
    );
  }

  PreferredSizeWidget? _appBarBanner(int transposeOffset) {
    if (_phase == LessonPhase.sing) {
      return const PreferredSize(
        preferredSize: Size.fromHeight(24),
        child: Padding(
          padding: EdgeInsets.only(bottom: 6),
          child: Text(
            '● SING',
            style: TextStyle(
              color: _gold,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
      );
    }
    if (transposeOffset != 0) {
      return PreferredSize(
        preferredSize: const Size.fromHeight(24),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            '♪ Adjusted for your voice',
            style: TextStyle(
              color: _gold.withAlpha(180),
              fontSize: 12,
            ),
          ),
        ),
      );
    }
    return null;
  }

  Widget _buildListenControls(bool isPlaying) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            iconSize: 64,
            icon: Icon(
              isPlaying ? Icons.pause_circle : Icons.play_circle,
              color: _gold,
            ),
            onPressed: () =>
                isPlaying ? _audioService.pause() : _audioService.play(),
          ),
          const SizedBox(height: 4),
          ElevatedButton.icon(
            onPressed: _enterSingPhase,
            icon: const Icon(Icons.mic),
            label: const Text('Sing It'),
          ),
        ],
      ),
    );
  }

  Widget _buildSingControls() {
    // The rich Sing-phase UI (countdown ring, per-phrase scoring, "Hear It")
    // arrives in ORT-44/45/46. For now the live voice bar on the track gives
    // real-time feedback and this returns the user to the Listen phase.
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: TextButton.icon(
        onPressed: _exitSingPhase,
        icon: const Icon(Icons.arrow_back, color: Colors.white70),
        label: const Text(
          'Back to Listen',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}
