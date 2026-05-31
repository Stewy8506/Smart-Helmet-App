import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

enum VoiceState { idle, listening, processing, speaking, error }

class VoiceAssistantService {
  static final VoiceAssistantService instance = VoiceAssistantService._();

  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  final ValueNotifier<VoiceState> state = ValueNotifier(VoiceState.idle);
  final ValueNotifier<String> recognizedText = ValueNotifier('');
  final ValueNotifier<double> soundLevel = ValueNotifier(0.0);

  final Map<String, dynamic> conversationContext = {};
  bool _expectingFollowUp = false;

  bool _isInitialized = false;
  Timer? _silenceTimer;
  Timer? _processingTimer;

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
        if (_expectingFollowUp) {
          _expectingFollowUp = false;
          startListening();
        } else {
          state.value = VoiceState.idle;
        }
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
      onSoundLevelChange: (level) {
        soundLevel.value = level;
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
    
    // Safety fallback: if processing gets stuck, reset after 5 seconds
    _processingTimer?.cancel();
    _processingTimer = Timer(const Duration(seconds: 5), () {
      if (state.value == VoiceState.processing) {
        resetToIdle();
      }
    });
  }

  void resetToIdle() {
    state.value = VoiceState.idle;
    _expectingFollowUp = false;
    _silenceTimer?.cancel();
    _processingTimer?.cancel();
  }

  Future<void> speak(String text, {bool expectFollowUp = false}) async {
    _processingTimer?.cancel();
    _expectingFollowUp = expectFollowUp;
    
    // Adaptive TTS based on speed
    try {
      final pos = await Geolocator.getLastKnownPosition();
      if (pos != null) {
        final speedKmh = pos.speed * 3.6;
        if (speedKmh > 80) {
          await _tts.setVolume(1.0);
          await _tts.setSpeechRate(0.35); // slower, louder
        } else if (speedKmh > 40) {
          await _tts.setVolume(1.0);
          await _tts.setSpeechRate(0.4);
        } else {
          await _tts.setVolume(0.8);
          await _tts.setSpeechRate(0.5);
        }
      } else {
        await _tts.setVolume(0.8);
        await _tts.setSpeechRate(0.5);
      }
    } catch (_) {}

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
    _processingTimer?.cancel();
    _stt.cancel();
    _tts.stop();
  }
}
