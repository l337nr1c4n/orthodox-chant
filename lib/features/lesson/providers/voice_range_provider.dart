import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/preferences_service.dart';

final voiceOffsetProvider = FutureProvider<int>((ref) async {
  return PreferencesService().getVoiceOffset();
});
