import 'package:flutter/material.dart';
import '../models/chant_phrase.dart';

/// Scrolling karaoke-style pitch track.
///
/// A fixed vertical cursor stays at the center of the screen.
/// Note blocks scroll left past it as the audio plays.
/// Each block is drawn at the pitch height of its syllable.
/// At the cursor: a gold bar shows the target; a colored bar shows the voice.
class PitchTrackWidget extends StatelessWidget {
  final List<ChantPhrase> phrases;
  final int currentIndex;
  final int positionMs; // current audio position in milliseconds
  final String? detectedNote;

  const PitchTrackWidget({
    super.key,
    required this.phrases,
    required this.currentIndex,
    required this.positionMs,
    required this.detectedNote,
  });

  static const double _height = 240.0;
  static const double _axisW = 40.0;
  static const int _midiMin = 59; // B3
  static const int _midiMax = 65; // F4
  static const _axisLabels = ['E4', 'D4', 'C4'];

  static int? _toMidi(String? note) {
    if (note == null) return null;
    const names = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    final match = RegExp(r'^([A-G]#?)(-?\d+)$').firstMatch(note);
    if (match == null) return null;
    final idx = names.indexOf(match.group(1)!);
    if (idx < 0) return null;
    return (int.parse(match.group(2)!) + 1) * 12 + idx;
  }

  static double _midiToFrac(int midi) =>
      (_midiMax - midi) / (_midiMax - _midiMin);

  @override
  Widget build(BuildContext context) {
    final targetMidi = currentIndex < phrases.length
        ? _toMidi(phrases[currentIndex].targetNote)
        : null;

    return SizedBox(
      height: _height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Y-axis note labels
          SizedBox(
            width: _axisW,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (final label in _axisLabels)
                  Positioned(
                    right: 6,
                    top: _midiToFrac(_toMidi(label)!) * _height - 8,
                    child: Text(
                      label,
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ),
                const Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: VerticalDivider(color: Colors.white12, width: 1),
                ),
              ],
            ),
          ),
          // Scrolling track
          Expanded(
            child: ClipRect(
              child: CustomPaint(
                painter: _TrackPainter(
                  phrases: phrases,
                  currentIndex: currentIndex,
                  positionMs: positionMs,
                  targetMidi: targetMidi,
                  detectedMidi: _toMidi(detectedNote),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackPainter extends CustomPainter {
  // How many pixels represent 1 millisecond of audio
  static const double _pxPerMs = 0.14;
  // Note block dimensions
  static const double _blockW = 88.0;
  static const double _blockH = 28.0;
  // Y-axis MIDI range
  static const int _midiMin = 59;
  static const int _midiMax = 65;
  static const _gold = Color(0xFFCFB53B);

  final List<ChantPhrase> phrases;
  final int currentIndex;
  final int positionMs;
  final int? targetMidi;
  final int? detectedMidi;

  const _TrackPainter({
    required this.phrases,
    required this.currentIndex,
    required this.positionMs,
    this.targetMidi,
    this.detectedMidi,
  });

  double _midiToY(int midi, double height) =>
      (_midiMax - midi) / (_midiMax - _midiMin) * height;

  static int? _toMidi(String note) {
    const names = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    final match = RegExp(r'^([A-G]#?)(-?\d+)$').firstMatch(note);
    if (match == null) return null;
    final idx = names.indexOf(match.group(1)!);
    if (idx < 0) return null;
    return (int.parse(match.group(2)!) + 1) * 12 + idx;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2; // cursor X (fixed center)

    // Faint horizontal grid lines at C4, D4, E4
    final gridPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1;
    for (final midi in [60, 62, 64]) {
      final y = _midiToY(midi, size.height);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Note blocks for each phrase
    for (int i = 0; i < phrases.length; i++) {
      final phrase = phrases[i];
      final midi = _toMidi(phrase.targetNote);
      if (midi == null) continue;

      // X offset relative to cursor based on time
      final blockX = cx + (phrase.audioOffsetMs - positionMs) * _pxPerMs;

      // Cull blocks that are fully off-screen
      if (blockX < -_blockW || blockX > size.width + _blockW) continue;

      final blockY = _midiToY(midi, size.height);
      final isActive = i == currentIndex;
      final isPast = i < currentIndex;

      final Color blockColor;
      final double w;
      final double h;
      if (isActive) {
        blockColor = _gold;
        w = _blockW + 10;
        h = _blockH + 8;
      } else if (isPast) {
        blockColor = Colors.white10;
        w = _blockW;
        h = _blockH;
      } else {
        blockColor = Colors.white24;
        w = _blockW;
        h = _blockH;
      }

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(blockX, blockY), width: w, height: h),
          const Radius.circular(6),
        ),
        Paint()..color = blockColor,
      );

      // Transliteration above block (pronunciation guide)
      _drawText(
        canvas,
        phrase.transliteration,
        blockX,
        blockY - h / 2 - 6,
        isActive
            ? const TextStyle(
                color: _gold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              )
            : const TextStyle(color: Colors.white38, fontSize: 13),
        anchorBottom: true,
      );

      // Greek below block
      _drawText(
        canvas,
        phrase.greek,
        blockX,
        blockY + h / 2 + 4,
        isActive
            ? const TextStyle(color: _gold, fontSize: 13)
            : const TextStyle(color: Colors.white24, fontSize: 11),
        anchorBottom: false,
      );
    }

    // Vertical cursor line
    canvas.drawLine(
      Offset(cx, 0),
      Offset(cx, size.height),
      Paint()
        ..color = Colors.white24
        ..strokeWidth = 1.5,
    );

    // ── Two bars at the cursor ──────────────────────────────────
    // Bar 1: gold target bar (where you need to sing)
    if (targetMidi != null) {
      final ty = _midiToY(targetMidi!, size.height);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, ty), width: 72, height: 12),
          const Radius.circular(6),
        ),
        Paint()..color = _gold,
      );
    }

    // Bar 2: voice bar (where you are singing) — moves in real-time
    if (detectedMidi != null) {
      final dy = _midiToY(detectedMidi!, size.height);

      final Color barColor;
      if (targetMidi == null) {
        barColor = Colors.white70;
      } else if (detectedMidi == targetMidi) {
        barColor = Colors.greenAccent;
      } else if (detectedMidi! > targetMidi!) {
        barColor = Colors.redAccent;
      } else {
        barColor = Colors.lightBlueAccent;
      }

      // Glow
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, dy), width: 80, height: 22),
          const Radius.circular(11),
        ),
        Paint()..color = barColor.withAlpha(50),
      );
      // Solid bar
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, dy), width: 56, height: 12),
          const Radius.circular(6),
        ),
        Paint()..color = barColor,
      );
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    double centerX,
    double edgeY,
    TextStyle style, {
    required bool anchorBottom, // true = edgeY is bottom of text
  }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: _blockW + 20);
    final dx = centerX - tp.width / 2;
    final dy = anchorBottom ? edgeY - tp.height : edgeY;
    tp.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(_TrackPainter old) =>
      old.positionMs != positionMs ||
      old.detectedMidi != detectedMidi ||
      old.currentIndex != currentIndex;
}
