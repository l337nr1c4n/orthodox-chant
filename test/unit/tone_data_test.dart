import 'package:flutter_test/flutter_test.dart';
import 'package:orthodox_chant/features/tones/data/tone_data.dart';

void main() {
  group('toneData', () {
    test('has all 8 tones of the Octoechos, ids 1..8 in order', () {
      expect(toneData.map((t) => t.id), ['1', '2', '3', '4', '5', '6', '7', '8']);
    });

    test('only Tone 1 is available', () {
      final available = toneData.where((t) => t.isAvailable).toList();
      expect(available.length, 1);
      expect(available.single.id, '1');
    });

    test('Tone 1 is fully populated', () {
      final t1 = toneData.firstWhere((t) => t.id == '1');
      expect(t1.character, isNotEmpty);
      expect(t1.usage, isNotEmpty);
      expect(t1.sampleHymnId, 'tone1_kyrie');
      expect(t1.hymns.map((h) => h.id), ['tone1_kyrie', 'tone1_trisagion']);
    });

    test('Tones 2–8 are locked placeholders with no hymns', () {
      for (final t in toneData.where((t) => t.id != '1')) {
        expect(t.isAvailable, isFalse, reason: 'tone ${t.id} should be locked');
        expect(t.hymns, isEmpty, reason: 'tone ${t.id} should have no hymns');
      }
    });
  });
}
