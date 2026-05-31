import 'dart:async';
import 'package:flutter/services.dart';

/// Thin Dart bridge to the native Kotlin VoiceBackend.
///
/// IMPORTANT: The EventChannel only supports a single listener.
/// We cache the broadcast stream so both VoiceAssistantService and
/// WakeWordService can listen to the same stream.
class NativeVoiceChannel {
  static const _method = MethodChannel('com.helmet.app/voice');
  static const _events = EventChannel('com.helmet.app/voice_events');

  /// Cached broadcast stream. Created once, shared by all listeners.
  static Stream<Map<String, dynamic>>? _broadcastStream;

  static Future<bool> initializeStt() async {
    final result = await _method.invokeMethod<bool>('initializeStt');
    return result ?? false;
  }

  static Future<void> startListening() async {
    await _method.invokeMethod('startListening');
  }

  static Future<void> stopListening() async {
    await _method.invokeMethod('stopListening');
  }

  static Future<void> cancelListening() async {
    await _method.invokeMethod('cancelListening');
  }

  static Future<void> speak(String text) async {
    await _method.invokeMethod('speak', {'text': text});
  }

  static Future<void> setSpeechRate(double rate) async {
    await _method.invokeMethod('setSpeechRate', {'rate': rate});
  }

  static Future<void> setVolume(double volume) async {
    await _method.invokeMethod('setVolume', {'volume': volume});
  }

  static Future<void> stopSpeaking() async {
    await _method.invokeMethod('stopSpeaking');
  }

  /// Returns a cached broadcast stream that multiple listeners can subscribe to.
  /// This is critical: EventChannel only supports ONE native listener,
  /// so we must convert it to a broadcast stream and reuse it.
  static Stream<Map<String, dynamic>> get events {
    _broadcastStream ??= _events
        .receiveBroadcastStream()
        .map((e) => Map<String, dynamic>.from(e))
        .asBroadcastStream();
    return _broadcastStream!;
  }
}
