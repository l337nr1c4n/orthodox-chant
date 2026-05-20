import 'package:flutter/material.dart';
import '../models/chant_phrase.dart';

/// Scrolling karaoke-style pitch track.
///
/// A fixed vertical cursor stays at the center of the screen.
/// Note blocks scroll left past it as the audio plays.
/// Each block is drawn at the pitch height of its syllable.
/// At the cursor: a gold bar shows the target; a colored bar shows the voice.
///
/// Visible MIDI range slides with [transposeOffset] so calibrated users
/// (whose phrase notes are pre-transposed) still see the gold bar and
/// blocks on-canvas.
class PitchTrackWidget extends StatelessWidget {
  final List<ChantPhrase> phrases;
  final int currentIndex;
  final int positionMs; // current audio position in milliseconds
  final String? detectedNote;
  final int transposeOffset;

  const PitchTrackWidget({
    super.key,
    required this.phrases,
    required this.currentIndex,
    required this.positionMs,
    required this.detectedNote,
    this.transposeOffset = 0,
  });

  static const double _height = 240.0;
  static const double _axisW = 40.0;

  // Base MIDI window when transposeOffset == 0.
  // Shifts with the offset so the user's transposed notes stay on-canvas.
  static const int _baseMidiMin = 55; // G3
  static const int _baseMidiMax = 65; // F4

  static const _noteNames = [
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
  ];

  static String _midiToName(int midi) {
    final octave = (midi ~/ 12) - 1;
    return '${_noteNames[midi % 12]}$octave';
  }

  static int? _toMidi(String? note) {
    if (note == null) return null;
    final match = RegExp(r'^([A-G]#?)(-?\d+)$').firstMatch(note);
    if (match == null) return null;
    final idx = _noteNames.indexOf(match.group(1)!);
    if (idx < 0) return null;
    return (int.parse(match.group(2)!) + 1) * 12 + idx;
  }

  @override
  Widget build(BuildContext context) {
    final visMidiMin = _baseMidiMin + transposeOffset;
    final visMidiMax = _baseMidiMax + transposeOffset;

    // 5 evenly-spaced MIDIs across the visible range (top → bottom).
    final axisMidis = [
      visMidiMax - 1,
      visMidiMax - 3,
      visMidiMax - 5,
      visMidiMin + 2,
      visMidiMin,
    ];

    double midiToFrac(int midi) =>
        (visMidiMax - midi) / (visMidiMax - visMidiMin);

    final rawTargetMidi = currentIndex < phrases.length
        ? _toMidi(phrases[currentIndex].targetNote)
        : null;
    final targetMidi =
        rawTargetMidi != null ? rawTargetMidi + transposeOffset : null;

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
                for (final m in axisMidis)
                  Positioned(
                    right: 6,
                    top: midiToFrac(m) * _height - 8,
                    child: Text(
                      _midiToName(m),
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 11),
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
                size: Size.infinite,
                painter: _TrackPainter(
                  phrases: phrases,
                  currentIndex: currentIndex,
                  positionMs: positionMs,
                  targetMidi: targetMidi,
                  detectedMidi: _toMidi(detectedNote),
                  transposeOffset: transposeOffset,
                  visMidiMin: visMidiMin,
                  visMidiMax: visMidiMax,
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
  static const _gold = Color(0xFFCFB53B);

  final List<ChantPhrase> phrases;
  final int currentIndex;
  final int positionMs;
  final int? targetMidi;
  final int? detectedMidi;
  final int transposeOffset;
  final int visMidiMin;
  final int visMidiMax;

  const _TrackPainter({
    required this.phrases,
    required this.currentIndex,
    required this.positionMs,
    required this.visMidiMin,
    required this.visMidiMax,
    this.targetMidi,
    this.detectedMidi,
    this.transposeOffset = 0,
  });

  double _midiToY(int midi, double height) =>
      (visMidiMax - midi) / (visMidiMax - visMidiMin) * height;

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

    // Faint horizontal grid lines across the visible range.
    final gridPaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1;
    final gridMidis = [
      visMidiMin,
      visMidiMin + 2,
      visMidiMin + 5,
      visMidiMin + 7,
      visMidiMax - 1,
    ];
    for (final midi in gridMidis) {
      final y = _midiToY(midi, size.height);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Note blocks for each phrase
    for (int i = 0; i < phrases.length; i++) {
      final phrase = phrases[i];
      final rawMidi = _toMidi(phrase.targetNote);
      if (rawMidi == null) continue;
      final midi = rawMidi + transposeOffset;

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
      final dy = _midiToY(detectedMidi!, size.height).clamp(0.0, size.height);

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
      old.currentIndex != currentIndex ||
      old.transposeOffset != transposeOffset ||
      old.visMidiMin != visMidiMin ||
      old.visMidiMax != visMidiMax;
}
