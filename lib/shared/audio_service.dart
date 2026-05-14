import 'package:just_audio/just_audio.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  Stream<Duration> get positionStream => _player.createPositionStream(
        minPeriod: const Duration(milliseconds: 50),
        maxPeriod: const Duration(milliseconds: 100),
      );
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  Future<void> loadAsset(String assetPath) async {
    try {
      await _player.stop();
      await _player.setAudioSource(AudioSource.asset(assetPath));
    } catch (_) {}
  }

  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();
  Future<void> stop() => _player.stop();
  Future<void> seekToStart() => _player.seek(Duration.zero);
  Future<void> setVolume(double v) => _player.setVolume(v);
  Future<void> dispose() => _player.dispose();
}
