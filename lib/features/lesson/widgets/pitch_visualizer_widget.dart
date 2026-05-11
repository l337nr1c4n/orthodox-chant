import 'package:flutter/material.dart';

class PitchVisualizerWidget extends StatelessWidget {
  final String? targetNote;
  final String? detectedNote;

  const PitchVisualizerWidget({
    super.key,
    required this.targetNote,
    required this.detectedNote,
  });

  static const _height = 200.0;
  static const _axisWidth = 44.0;
  static const _midiMin = 59; // B3 — bottom padding
  static const _midiMax = 65; // F4 — top padding
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
    return SizedBox(
      height: _height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Y-axis labels
          SizedBox(
            width: _axisWidth,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (final label in _axisLabels)
                  Positioned(
                    right: 8,
                    top: _midiToFrac(_toMidi(label)!) * _height - 8,
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: VerticalDivider(color: Colors.white24, width: 1),
                ),
              ],
            ),
          ),
          // Pitch visualizer area
          Expanded(
            child: CustomPaint(
              painter: _VisualizerPainter(
                targetMidi: _toMidi(targetNote),
                detectedMidi: _toMidi(detectedNote),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VisualizerPainter extends CustomPainter {
  static const _midiMin = 59;
  static const _midiMax = 65;

  final int? targetMidi;
  final int? detectedMidi;

  const _VisualizerPainter({this.targetMidi, this.detectedMidi});

  double _toY(int midi, double height) =>
      (_midiMax - midi) / (_midiMax - _midiMin) * height;

  @override
  void paint(Canvas canvas, Size size) {
    const gold = Color(0xFFCFB53B);

    // Faint horizontal grid lines at C4, D4, E4
    final gridPaint = Paint()
      ..color = Colors.white12
      ..strokeWidth = 1;
    for (final midi in [60, 62, 64]) {
      final y = _toY(midi, size.height);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Target band — gold horizontal line with translucent fill
    if (targetMidi != null) {
      final ty = _toY(targetMidi!, size.height);
      canvas.drawRect(
        Rect.fromLTRB(0, ty - 16, size.width, ty + 16),
        Paint()..color = gold.withAlpha(50),
      );
      canvas.drawLine(
        Offset(0, ty),
        Offset(size.width, ty),
        Paint()
          ..color = gold
          ..strokeWidth = 2.5,
      );
    }

    // Detected pitch — colored dot that floats on the Y axis
    if (detectedMidi != null) {
      final dy = _toY(detectedMidi!, size.height);
      final Color dotColor;
      if (targetMidi == null) {
        dotColor = Colors.white54;
      } else if (detectedMidi == targetMidi) {
        dotColor = Colors.greenAccent;
      } else if (detectedMidi! > targetMidi!) {
        dotColor = Colors.redAccent;
      } else {
        dotColor = Colors.lightBlueAccent;
      }
      // Glow
      canvas.drawCircle(
        Offset(size.width / 2, dy),
        20,
        Paint()..color = dotColor.withAlpha(55),
      );
      // Solid dot
      canvas.drawCircle(
        Offset(size.width / 2, dy),
        12,
        Paint()..color = dotColor,
      );
    }
  }

  @override
  bool shouldRepaint(_VisualizerPainter old) =>
      old.targetMidi != targetMidi || old.detectedMidi != detectedMidi;
}
