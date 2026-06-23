import 'dart:math';

/// Music-math helpers shared across the pitch pipeline.
///
/// Single source of truth for converting between frequencies, note names
/// (e.g. "D4"), and MIDI note numbers. Previously these conversions were
/// copy-pasted across the pitch service, providers, screens, and widgets.

/// Chromatic note names indexed by pitch class (0 = C ... 11 = B).
const List<String> noteNames = [
  'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
];

/// Converts a frequency in Hz to its nearest note name (e.g. 440.0 -> "A4").
/// Returns null for non-positive frequencies. Reference: A4 = 440 Hz = MIDI 69.
String? hzToNoteName(double hz) {
  if (hz <= 0) return null;
  final midi = (12 * (log(hz / 440.0) / log(2)) + 69).round();
  return midiToNoteName(midi);
}

/// Parses a note name (e.g. "D4", "C#3", "A-1") to a MIDI note number.
/// Returns null if the string is not a valid note name.
int? noteToMidi(String note) {
  final match = RegExp(r'^([A-G]#?)(-?\d+)$').firstMatch(note);
  if (match == null) return null;
  final idx = noteNames.indexOf(match.group(1)!);
  if (idx < 0) return null;
  return (int.parse(match.group(2)!) + 1) * 12 + idx;
}

/// Converts a MIDI note number to its note name (e.g. 69 -> "A4").
String midiToNoteName(int midi) {
  final octave = (midi ~/ 12) - 1;
  return '${noteNames[midi % 12]}$octave';
}
