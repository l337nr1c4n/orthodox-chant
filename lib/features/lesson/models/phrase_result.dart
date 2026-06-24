import '../../../core/note_utils.dart';
import 'chant_phrase.dart';

/// The outcome of scoring one phrase during the Sing phase.
class PhraseResult {
  final ChantPhrase phrase;

  /// Fraction (0.0–1.0) of captured readings that were in tune.
  final double accuracy;

  const PhraseResult({required this.phrase, required this.accuracy});

  /// A phrase passes when the singer was in tune for most of the window.
  bool get passed => accuracy >= 0.6;

  /// Fraction of [readings] (detected note names, may be null for unpitched
  /// frames) that land within one semitone of [targetMidi]. Silence and
  /// unpitched frames count against the score, so the singer must actually
  /// hold the note. Returns 0.0 for an empty window.
  static double accuracyOf(List<String?> readings, int targetMidi) {
    if (readings.isEmpty) return 0.0;
    var hits = 0;
    for (final note in readings) {
      if (note == null) continue;
      final midi = noteToMidi(note);
      if (midi != null && (midi - targetMidi).abs() <= 1) hits++;
    }
    return hits / readings.length;
  }
}
