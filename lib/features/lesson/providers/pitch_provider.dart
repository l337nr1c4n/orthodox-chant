import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/pitch_service.dart';

enum PitchFeedback { tooLow, correct, tooHigh, inactive }

final pitchServiceProvider = Provider<PitchService>((ref) {
  return PitchService();
});

final detectedNoteProvider = StreamProvider<String?>((ref) {
  final service = ref.watch(pitchServiceProvider);
  ref.onDispose(() => service.stop());
  service.start();
  return service.noteStream;
});

final pitchFeedbackProvider = Provider.family<PitchFeedback, String>((ref, targetNote) {
  return ref.watch(detectedNoteProvider).when(
    data: (note) {
      if (note == null) return PitchFeedback.inactive;
      final detected = _noteToMidi(note);
      final target = _noteToMidi(targetNote);
      if (detected == null || target == null) return PitchFeedback.inactive;
      final diff = detected - target;
      if (diff == 0) return PitchFeedback.correct;
      return diff < 0 ? PitchFeedback.tooLow : PitchFeedback.tooHigh;
    },
    loading: () => PitchFeedback.inactive,
    error: (_, _) => PitchFeedback.inactive,
  );
});

int? _noteToMidi(String note) {
  const names = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
  final match = RegExp(r'^([A-G]#?)(-?\d+)$').firstMatch(note);
  if (match == null) return null;
  final idx = names.indexOf(match.group(1)!);
  if (idx < 0) return null;
  return (int.parse(match.group(2)!) + 1) * 12 + idx;
}
