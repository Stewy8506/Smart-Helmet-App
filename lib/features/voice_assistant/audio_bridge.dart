import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';

class AudioBridge {
  static final AudioBridge instance = AudioBridge._();
  AudioBridge._();

  AudioHandler? _handler;

  void setHandler(AudioHandler handler) {
    _handler = handler;
  }

  Future<void> play() async {
    if (_handler != null) {
      await _handler!.play();
    } else {
      debugPrint('AudioHandler not initialized yet');
    }
  }

  Future<void> pause() async {
    if (_handler != null) {
      await _handler!.pause();
    } else {
      debugPrint('AudioHandler not initialized yet');
    }
  }

  Future<void> skipToNext() async {
    if (_handler != null) {
      await _handler!.skipToNext();
    } else {
      debugPrint('AudioHandler not initialized yet');
    }
  }

  Future<void> skipToPrevious() async {
    if (_handler != null) {
      await _handler!.skipToPrevious();
    } else {
      debugPrint('AudioHandler not initialized yet');
    }
  }
}
