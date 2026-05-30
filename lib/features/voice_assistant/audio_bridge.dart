import 'package:helmet_app/features/spotify/spotify_service.dart';

class AudioBridge {
  static final AudioBridge instance = AudioBridge._();
  AudioBridge._();

  Future<void> play() async {
    await SpotifyService.instance.play();
  }

  Future<void> pause() async {
    await SpotifyService.instance.pause();
  }

  Future<void> skipToNext() async {
    await SpotifyService.instance.skipNext();
  }

  Future<void> skipToPrevious() async {
    await SpotifyService.instance.skipPrevious();
  }
}
