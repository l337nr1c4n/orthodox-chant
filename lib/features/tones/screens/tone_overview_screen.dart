import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/preferences_service.dart';
import '../../../core/tone_repository.dart';
import '../../../shared/audio_service.dart';
import '../../library/widgets/hymn_card.dart';
import '../data/tone_data.dart';
import '../models/tone_info.dart';

const Color _gold = Color(0xFFCFB53B);

/// Chapter page for a single tone: its name, a short audio preview, its
/// character + liturgical usage, and the list of hymns with completion marks.
class ToneOverviewScreen extends StatefulWidget {
  final String toneId;

  const ToneOverviewScreen({super.key, required this.toneId});

  @override
  State<ToneOverviewScreen> createState() => _ToneOverviewScreenState();
}

class _ToneOverviewScreenState extends State<ToneOverviewScreen> {
  late final ToneInfo _tone;
  late final Future<Set<String>> _completedFuture;
  final AudioService _audio = AudioService();
  Timer? _previewTimer;
  bool _previewPlaying = false;

  @override
  void initState() {
    super.initState();
    _tone = toneData.firstWhere((t) => t.id == widget.toneId);
    _completedFuture = PreferencesService().getCompletedHymns();
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    _audio.dispose();
    super.dispose();
  }

  /// Plays the first 5 seconds of the tone's sample hymn, then pauses. A second
  /// tap stops it early.
  Future<void> _toggleHearTone() async {
    if (_previewPlaying) {
      _previewTimer?.cancel();
      await _audio.pause();
      if (mounted) setState(() => _previewPlaying = false);
      return;
    }
    try {
      final data = await loadHymn(_tone.sampleHymnId);
      await _audio.loadAsset('assets/audio/tone1/${data.hymn}.wav');
      await _audio.seekToStart();
      await _audio.setVolume(0.6);
      await _audio.play();
    } catch (_) {
      return;
    }
    if (!mounted) return;
    setState(() => _previewPlaying = true);
    _previewTimer = Timer(const Duration(seconds: 5), () async {
      await _audio.pause();
      if (mounted) setState(() => _previewPlaying = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orthodox Chant'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _tone.greekName,
              textAlign: TextAlign.center,
              style: GoogleFonts.cinzel(
                color: _gold,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _tone.name,
              textAlign: TextAlign.center,
              style: GoogleFonts.cinzel(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  IconButton(
                    iconSize: 56,
                    icon: Icon(
                      _previewPlaying
                          ? Icons.pause_circle
                          : Icons.play_circle,
                      color: _gold,
                    ),
                    onPressed: _toggleHearTone,
                  ),
                  Text(
                    'Hear This Tone',
                    style: GoogleFonts.robotoSerif(
                      color: Colors.white54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.white12),
            const SizedBox(height: 16),
            Text(
              _tone.character,
              style: GoogleFonts.robotoSerif(
                color: Colors.white70,
                fontSize: 15,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _tone.usage,
              style: GoogleFonts.robotoSerif(
                color: Colors.white38,
                fontSize: 12,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'HYMNS',
              style: GoogleFonts.cinzel(
                color: Colors.white54,
                fontSize: 14,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<Set<String>>(
              future: _completedFuture,
              builder: (context, snapshot) {
                final completed = snapshot.data ?? const <String>{};
                return Column(
                  children: [
                    for (final hymn in _tone.hymns)
                      HymnCard(
                        title: hymn.title,
                        subtitle: hymn.subtitle,
                        leading: hymn.iconAsset != null
                            ? Image.asset(hymn.iconAsset!, width: 40, height: 40)
                            : const Icon(Icons.music_note, color: _gold),
                        trailing: completed.contains(hymn.id)
                            ? const Icon(Icons.check_circle, color: _gold)
                            : const Icon(Icons.chevron_right, color: _gold),
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/lesson',
                          arguments: hymn.id,
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
