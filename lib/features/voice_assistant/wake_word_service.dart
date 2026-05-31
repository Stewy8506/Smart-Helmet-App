import 'package:flutter/foundation.dart';
import 'dart:async';
import 'voice_assistant_service.dart';
import 'native_voice_channel.dart';

class WakeWordService {
  static final WakeWordService instance = WakeWordService._();
  WakeWordService._();

  bool _isRunning = false;   // True when actively listening for wake words
  bool _isPaused = false;    // True when main voice assistant has taken over
  bool _isInitialized = false;
  Timer? _restartTimer;
  StreamSubscription? _eventSubscription;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true; // Mark early to prevent re-entry

    await NativeVoiceChannel.initializeStt();
    
    _eventSubscription?.cancel();
    _eventSubscription = NativeVoiceChannel.events.listen(_onEvent);
  }

  void _onEvent(Map<String, dynamic> event) {
    // Ignore all events if we're paused or not running
    if (_isPaused || !_isRunning) return;

    final type = event['type'] as String?;

    if (type == 'status') {
      if (event['value'] == 'notListening') {
        // The recognizer session ended (either results, error, or timeout).
        // Schedule a restart to keep listening for wake words.
        _scheduleRestart();
      }
    } else if (type == 'result') {
      final text = (event['text'] as String?)?.toLowerCase() ?? '';
      if (text.contains('hey helmet') || text.contains('hello helmet')) {
        debugPrint("WakeWordService: Wake word detected in '$text'");
        // Hand off to the main voice assistant.
        // pause() sets _isPaused=true and cancels our mic session.
        // Then we tell the voice assistant to start its own session.
        _isPaused = true;
        _isRunning = false;
        _restartTimer?.cancel();
        // Cancel our listening session — the voice assistant will start its own.
        NativeVoiceChannel.cancelListening();
        // Small delay to let the cancel propagate before the voice assistant starts.
        Future.delayed(const Duration(milliseconds: 150), () {
          VoiceAssistantService.instance.startListening();
        });
      }
    }
    // We intentionally ignore 'error' events here.
    // Errors (like ERROR_NO_MATCH = 7) are followed by 'notListening',
    // which triggers _scheduleRestart above. No special handling needed.
  }

  void _scheduleRestart() {
    if (!_isRunning || _isPaused) return;
    _restartTimer?.cancel();
    _restartTimer = Timer(const Duration(milliseconds: 800), () {
      if (_isRunning && !_isPaused) {
        _startInternal();
      }
    });
  }

  Future<void> startListening() async {
    if (!_isInitialized) await initialize();
    _isRunning = true;
    _isPaused = false;
    _startInternal();
  }

  void pause() {
    debugPrint("WakeWordService: paused");
    _isPaused = true;
    _isRunning = false;
    _restartTimer?.cancel();
    NativeVoiceChannel.cancelListening();
  }

  void resume() {
    debugPrint("WakeWordService: resumed");
    _isPaused = false;
    startListening();
  }

  void _startInternal() {
    if (_isPaused) return;

    // Yield the microphone if the main voice assistant is currently active
    if (VoiceAssistantService.instance.state.value != VoiceState.idle) {
      _scheduleRestart();
      return;
    }

    debugPrint("WakeWordService: starting STT for wake word detection");
    NativeVoiceChannel.startListening();
  }

  Future<void> stopListening() async {
    _isRunning = false;
    _restartTimer?.cancel();
    await NativeVoiceChannel.cancelListening();
  }

  void dispose() {
    _isRunning = false;
    _isPaused = true;
    _restartTimer?.cancel();
    _eventSubscription?.cancel();
    NativeVoiceChannel.cancelListening();
  }
}
