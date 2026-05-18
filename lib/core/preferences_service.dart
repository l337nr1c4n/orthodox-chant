import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const _onboardingKey = 'onboarding_complete';
  static const _offsetKey = 'voice_offset_semitones';

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
}
