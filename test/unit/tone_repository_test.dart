import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:orthodox_chant/core/tone_repository.dart';

const _kyrieJson = '''
{
  "tone": "1",
  "hymn": "kyrie_eleison",
  "phrases": [
    { "greek": "Κύ",   "transliteration": "Ky",  "target_note": "D4", "audio_offset_ms": 0    },
    { "greek": "ρι",   "transliteration": "ri",  "target_note": "E4", "audio_offset_ms": 800  },
    { "greek": "ε",    "transliteration": "e",   "target_note": "D4", "audio_offset_ms": 1600 },
    { "greek": "ε",    "transliteration": "e",   "target_note": "C4", "audio_offset_ms": 2400 },
    { "greek": "λέ",   "transliteration": "lei", "target_note": "D4", "audio_offset_ms": 3200 },
    { "greek": "η",    "transliteration": "i",   "target_note": "E4", "audio_offset_ms": 4000 },
    { "greek": "σον",  "transliteration": "son", "target_note": "D4", "audio_offset_ms": 4800 }
  ]
}
''';

void main() {
  group('parsePhrases', () {
    test('returns 7 phrases for Kyrie JSON', () {
      final phrases = parsePhrases(jsonDecode(_kyrieJson) as Map<String, dynamic>);
      expect(phrases.length, equals(7));
    });

    test('all phrases have non-empty greek text', () {
      final phrases = parsePhrases(jsonDecode(_kyrieJson) as Map<String, dynamic>);
      for (final phrase in phrases) {
        expect(phrase.greek, isNotEmpty);
      }
    });

    test('all phrases have non-negative audioOffsetMs', () {
      final phrases = parsePhrases(jsonDecode(_kyrieJson) as Map<String, dynamic>);
      for (final phrase in phrases) {
        expect(phrase.audioOffsetMs, greaterThanOrEqualTo(0));
      }
    });

    test('offsets are monotonically increasing', () {
      final phrases = parsePhrases(jsonDecode(_kyrieJson) as Map<String, dynamic>);
      for (int i = 1; i < phrases.length; i++) {
        expect(phrases[i].audioOffsetMs, greaterThan(phrases[i - 1].audioOffsetMs));
      }
    });
  });
}
