import 'package:helmet_app/features/music/local_audio_service.dart';

class AudioBridge {
  static final AudioBridge instance = AudioBridge._();
  AudioBridge._();

  Future<void> play() async {
    await LocalAudioService.instance.play();
  }

  Future<void> pause() async {
    await LocalAudioService.instance.pause();
  }

  Future<void> skipToNext() async {
    await LocalAudioService.instance.skipToNext();
  }

  Future<void> skipToPrevious() async {
    await LocalAudioService.instance.skipToPrevious();
  }
}
