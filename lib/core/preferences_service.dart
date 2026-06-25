import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const _onboardingKey = 'onboarding_complete';
  static const _offsetKey = 'voice_offset_semitones';
  static const _completedHymnsKey = 'completed_hymns';

  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  Future<int> getVoiceOffset() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_offsetKey) ?? 0;
  }

  Future<void> setVoiceOffset(int semitones) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_offsetKey, semitones);
  }

  /// Hymn ids the user has completed (a 2- or 3-star Sing run). Used by the
  /// result screen to record progress and by the tone overview to show ✓.
  Future<Set<String>> getCompletedHymns() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_completedHymnsKey) ?? const <String>[]).toSet();
  }

  Future<void> markHymnComplete(String hymnId) async {
    final prefs = await SharedPreferences.getInstance();
    final completed =
        (prefs.getStringList(_completedHymnsKey) ?? const <String>[]).toSet()
          ..add(hymnId);
    await prefs.setStringList(_completedHymnsKey, completed.toList());
  }
}
