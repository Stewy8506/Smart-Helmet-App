import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'dart:async';

enum VoiceState { idle, listening, processing, speaking, error }

class VoiceAssistantService {
  static final VoiceAssistantService instance = VoiceAssistantService._();

  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  final ValueNotifier<VoiceState> state = ValueNotifier(VoiceState.idle);
  final ValueNotifier<String> recognizedText = ValueNotifier('');

  bool _isInitialized = false;
  Timer? _silenceTimer;

  VoiceAssistantService._();

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _stt.initialize(
        onError: (errorNotification) {
          debugPrint('STT Error: ${errorNotification.errorMsg}');
          _setError('Microphone error: ${errorNotification.errorMsg}');
        },
        onStatus: (status) {
          debugPrint('STT Status: $status');
          if (status == 'notListening' && state.value == VoiceState.listening) {
            _stopAndProcess();
          }
        },
      );

      await _tts.setLanguage("en-US");
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      
      _tts.setCompletionHandler(() {
        state.value = VoiceState.idle;
      });

      return _isInitialized;
    } catch (e) {
      debugPrint('Error initializing VoiceAssistantService: $e');
      return false;
    }
  }

  Future<void> startListening() async {
    if (!_isInitialized) {
      final success = await initialize();
      if (!success) {
        _setError('Speech recognition is not available');
        return;
      }
    }

    state.value = VoiceState.listening;
    recognizedText.value = '';

    await _stt.listen(
      onResult: (result) {
        recognizedText.value = result.recognizedWords;
        _resetSilenceTimer();
      },
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      cancelOnError: true,
      listenMode: ListenMode.confirmation,
    );
    
    _resetSilenceTimer();
  }

  Future<void> stopListening() async {
    _silenceTimer?.cancel();
    if (_stt.isListening) {
      await _stt.stop();
    }
    _stopAndProcess();
  }

  void _stopAndProcess() {
    if (state.value != VoiceState.listening) return;
    _silenceTimer?.cancel();
    state.value = VoiceState.processing;
    // The UI will now show "Processing...". The IntentRouter will handle parsing.
  }

  Future<void> speak(String text) async {
    state.value = VoiceState.speaking;
    await _tts.speak(text);
  }

  void _resetSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(const Duration(seconds: 5), () {
      if (state.value == VoiceState.listening) {
        if (recognizedText.value.isEmpty) {
          stopListening();
          speak("I didn't catch that. Please try again.");
        } else {
          stopListening();
        }
      }
    });
  }

  void _setError(String msg) {
    state.value = VoiceState.error;
    speak(msg);
  }

  void dispose() {
    _silenceTimer?.cancel();
    _stt.cancel();
    _tts.stop();
  }
}
