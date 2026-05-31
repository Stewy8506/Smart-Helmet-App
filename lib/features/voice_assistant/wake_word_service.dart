import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'dart:async';
import 'voice_assistant_service.dart';

class WakeWordService {
  static final WakeWordService instance = WakeWordService._();
  WakeWordService._();

  final SpeechToText _stt = SpeechToText();
  bool _isListening = false;
  bool _isInitialized = false;
  Timer? _restartTimer;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = await _stt.initialize(
      onError: (val) {
        // Automatically restart if an error (like a timeout) occurs
        _scheduleRestart();
      },
      onStatus: (val) {
        if (val == 'notListening' && _isListening) {
          _scheduleRestart();
        }
      },
    );
  }

  void _scheduleRestart() {
    if (!_isListening) return;
    _restartTimer?.cancel();
    // Brief delay to allow the microphone hardware to release before restarting
    _restartTimer = Timer(const Duration(milliseconds: 500), () {
      if (_isListening && !_stt.isListening) {
        _startInternal();
      }
    });
  }

  Future<void> startListening() async {
    if (!_isInitialized) await initialize();
    _isListening = true;
    _startInternal();
  }

  void _startInternal() {
    // Yield the microphone if the main voice assistant is currently active
    if (VoiceAssistantService.instance.state.value != VoiceState.idle) {
      _scheduleRestart();
      return;
    }

    _stt.listen(
      onResult: (result) {
        final text = result.recognizedWords.toLowerCase();
        if (text.contains('hey helmet') || text.contains('hello helmet') || text.contains('helmet')) {
          debugPrint("Wake word detected: $text");
          _stt.stop();
          // Trigger the main voice assistant!
          VoiceAssistantService.instance.startListening();
        }
      },
      listenMode: ListenMode.dictation,
      partialResults: true,
      cancelOnError: true,
    );
  }

  Future<void> stopListening() async {
    _isListening = false;
    _restartTimer?.cancel();
    await _stt.stop();
  }

  void dispose() {
    _isListening = false;
    _restartTimer?.cancel();
    _stt.cancel();
  }
}
