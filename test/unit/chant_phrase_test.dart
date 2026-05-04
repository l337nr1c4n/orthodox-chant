import 'package:flutter_test/flutter_test.dart';
import 'package:orthodox_chant/features/lesson/models/chant_phrase.dart';

void main() {
  const sampleJson = {
    'greek': 'Κύ',
    'transliteration': 'Ky',
    'target_note': 'D4',
    'audio_offset_ms': 0,
  };

  group('ChantPhrase.fromJson', () {
    test('parses all fields correctly', () {
      final phrase = ChantPhrase.fromJson(sampleJson);
      expect(phrase.greek, equals('Κύ'));
      expect(phrase.transliteration, equals('Ky'));
      expect(phrase.targetNote, equals('D4'));
      expect(phrase.audioOffsetMs, equals(0));
    });

    test('round-trips through toJson', () {
      final phrase = ChantPhrase.fromJson(sampleJson);
      final json = phrase.toJson();
      final reparsed = ChantPhrase.fromJson(json);
      expect(reparsed.greek, equals(phrase.greek));
      expect(reparsed.targetNote, equals(phrase.targetNote));
      expect(reparsed.audioOffsetMs, equals(phrase.audioOffsetMs));
    });

    test('throws FormatException when targetNote is missing', () {
      final badJson = Map<String, dynamic>.from(sampleJson)
        ..remove('target_note');
      expect(() => ChantPhrase.fromJson(badJson), throwsFormatException);
    });
  });
}
