import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../../core/tone_repository.dart';
import '../models/chant_phrase.dart';
import '../providers/audio_provider.dart';
import '../providers/pitch_provider.dart';
import '../widgets/phrase_display_widget.dart';
import '../widgets/pitch_visualizer_widget.dart';

class LessonScreen extends ConsumerStatefulWidget {
  final String hymnId;

  const LessonScreen({super.key, required this.hymnId});

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  List<ChantPhrase> _phrases = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
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

  int _currentIndex(Duration position) {
    if (_phrases.isEmpty) return 0;
    final ms = position.inMilliseconds;
    final idx = _phrases.lastIndexWhere((p) => ms >= p.audioOffsetMs);
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    // Seek back to start when playback finishes so Play works again
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
    final detectedNote = ref.watch(detectedNoteProvider).valueOrNull;

    final currentIdx = position.when(
      data: _currentIndex,
      loading: () => 0,
      error: (_, _) => 0,
    );

    final targetNote =
        _phrases.isNotEmpty ? _phrases[currentIdx].targetNote : null;

    final isPlaying = playerState.when(
      data: (s) => s.playing,
      loading: () => false,
      error: (_, _) => false,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_phrases.isNotEmpty ? _phrases[0].greek : widget.hymnId),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                PhraseDisplayWidget(
                  phrases: _phrases,
                  currentIndex: currentIdx,
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: PitchVisualizerWidget(
                    targetNote: targetNote,
                    detectedNote: detectedNote,
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
