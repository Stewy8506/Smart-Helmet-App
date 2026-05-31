import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'wake_word_service.dart';
import 'native_voice_channel.dart';

enum VoiceState { idle, listening, processing, speaking, error }

class VoiceAssistantService {
  static final VoiceAssistantService instance = VoiceAssistantService._();

  final ValueNotifier<VoiceState> state = ValueNotifier(VoiceState.idle);
  final ValueNotifier<String> recognizedText = ValueNotifier('');
  final ValueNotifier<double> soundLevel = ValueNotifier(0.0);

  final Map<String, dynamic> conversationContext = {};
  bool _expectingFollowUp = false;

  bool _isInitialized = false;
  Timer? _silenceTimer;
  Timer? _processingTimer;
  StreamSubscription? _eventSubscription;

  VoiceAssistantService._();

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await NativeVoiceChannel.initializeStt();
      
      _eventSubscription?.cancel();
      _eventSubscription = NativeVoiceChannel.events.listen((event) {
        final type = event['type'] as String?;

        if (type == 'status') {
          final val = event['value'] as String?;
          if (val == 'notListening' && state.value == VoiceState.listening) {
            _stopAndProcess();
          }
        } else if (type == 'result') {
          // Only update if WE are the active listener (not wake word service)
          if (state.value == VoiceState.listening) {
            recognizedText.value = event['text'] as String? ?? '';
            _resetSilenceTimer();
          }
        } else if (type == 'soundLevel') {
          if (state.value == VoiceState.listening) {
            soundLevel.value = (event['level'] as num?)?.toDouble() ?? 0.0;
          }
        } else if (type == 'error') {
          final code = event['code'] as int? ?? -1;
          debugPrint('VoiceAssistant: STT Error code=$code');
          // Error 7 (ERROR_NO_MATCH) is benign — mic heard noise but no words.
          // Only report real errors to the user if we're actively listening.
          if (state.value == VoiceState.listening && code != 7) {
            // Don't call _setError here — it causes infinite loops
            // (speak -> ttsComplete -> idle -> wake word restarts -> error again)
            // Instead, just reset to idle so the user can try again.
            state.value = VoiceState.idle;
            WakeWordService.instance.resume();
          }
        } else if (type == 'ttsComplete') {
          if (_expectingFollowUp) {
            _expectingFollowUp = false;
            startListening();
          } else {
            state.value = VoiceState.idle;
            WakeWordService.instance.resume();
          }
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
        state.value = VoiceState.error;
        return;
      }
    }

    // Ensure wake word service gives up the mic
    WakeWordService.instance.pause();
    // Wait briefly to allow OS to release the microphone lock
    await Future.delayed(const Duration(milliseconds: 250));

    state.value = VoiceState.listening;
    recognizedText.value = '';
    soundLevel.value = 0.0;

    await NativeVoiceChannel.startListening();
    
    _resetSilenceTimer();
  }

  Future<void> stopListening() async {
    _silenceTimer?.cancel();
    // Use cancel (hard stop) so the mic is immediately freed.
    // stopListening() would leave the recognizer in a transcribing state.
    await NativeVoiceChannel.cancelListening();
    // _stopAndProcess will be called by the 'notListening' event from cancelListening.
    // But cancelListening also fires the event synchronously via sendEvent, so we
    // call _stopAndProcess directly to be safe.
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
    _silenceTimer?.cancel();
    _processingTimer?.cancel();
    _expectingFollowUp = false;
    state.value = VoiceState.idle;
    WakeWordService.instance.resume();
  }

  Future<void> speak(String text, {bool expectFollowUp = false}) async {
    _processingTimer?.cancel();
    _expectingFollowUp = expectFollowUp;
    
    // Adaptive TTS based on speed
    try {
      final pos = await Geolocator.getLastKnownPosition().timeout(const Duration(milliseconds: 200));
      if (pos != null) {
        final speedKmh = pos.speed * 3.6;
        if (speedKmh > 80) {
          await NativeVoiceChannel.setVolume(1.0);
          await NativeVoiceChannel.setSpeechRate(0.7); // slower at high speed for clarity
        } else if (speedKmh > 40) {
          await NativeVoiceChannel.setVolume(1.0);
          await NativeVoiceChannel.setSpeechRate(0.8);
        } else {
          await NativeVoiceChannel.setVolume(0.8);
          await NativeVoiceChannel.setSpeechRate(0.85);
        }
      } else {
        await NativeVoiceChannel.setVolume(0.8);
        await NativeVoiceChannel.setSpeechRate(0.85);
      }
    } catch (_) {
      // Fallback if timeout or no permission
      await NativeVoiceChannel.setVolume(0.8);
      await NativeVoiceChannel.setSpeechRate(0.85);
    }

    state.value = VoiceState.speaking;
    await NativeVoiceChannel.speak(text);
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

  void dispose() {
    _silenceTimer?.cancel();
    _processingTimer?.cancel();
    _eventSubscription?.cancel();
    NativeVoiceChannel.cancelListening();
    NativeVoiceChannel.stopSpeaking();
  }
}
