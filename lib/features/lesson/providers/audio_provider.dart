import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../../shared/audio_service.dart';

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(service.dispose);
  return service;
});

final positionProvider = StreamProvider<Duration>((ref) {
  return ref.watch(audioServiceProvider).positionStream;
});

final playerStateProvider = StreamProvider<PlayerState>((ref) {
  return ref.watch(audioServiceProvider).playerStateStream;
});
