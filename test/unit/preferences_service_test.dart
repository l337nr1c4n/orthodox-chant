import 'package:flutter_test/flutter_test.dart';
import 'package:orthodox_chant/core/preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('PreferencesService hymn completion', () {
    test('starts empty', () async {
      expect(await PreferencesService().getCompletedHymns(), isEmpty);
    });

    test('markHymnComplete persists a hymn id', () async {
      final prefs = PreferencesService();
      await prefs.markHymnComplete('tone1_kyrie');
      expect(await prefs.getCompletedHymns(), {'tone1_kyrie'});
    });

    test('marking is idempotent and accumulates distinct ids', () async {
      final prefs = PreferencesService();
      await prefs.markHymnComplete('tone1_kyrie');
      await prefs.markHymnComplete('tone1_kyrie');
      await prefs.markHymnComplete('tone1_trisagion');
      expect(
        await prefs.getCompletedHymns(),
        {'tone1_kyrie', 'tone1_trisagion'},
      );
    });
  });
}
