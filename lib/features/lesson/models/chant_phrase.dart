class ChantPhrase {
  final String greek;
  final String transliteration;
  final String targetNote;
  final int audioOffsetMs;

  const ChantPhrase({
    required this.greek,
    required this.transliteration,
    required this.targetNote,
    required this.audioOffsetMs,
  });

  factory ChantPhrase.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('target_note')) {
      throw const FormatException('missing required field: target_note');
    }
    return ChantPhrase(
      greek: json['greek'] as String,
      transliteration: json['transliteration'] as String,
      targetNote: json['target_note'] as String,
      audioOffsetMs: json['audio_offset_ms'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'greek': greek,
        'transliteration': transliteration,
        'target_note': targetNote,
        'audio_offset_ms': audioOffsetMs,
      };
}
