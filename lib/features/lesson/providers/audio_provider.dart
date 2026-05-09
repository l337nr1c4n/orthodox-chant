import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/audio_service.dart';

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(service.dispose);
  return service;
});

final positionProvider = StreamProvider<Duration>((ref) {
  return ref.watch(audioServiceProvider).positionStream;
});
