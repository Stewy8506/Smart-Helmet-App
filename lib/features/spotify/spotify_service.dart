import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:spotify_sdk/spotify_sdk.dart';

class SpotifyService {
  static final SpotifyService instance = SpotifyService._();
  SpotifyService._();

  bool _isConnected = false;

  bool get isConnected => _isConnected;

  Future<bool> connect() async {
    try {
      final clientId = dotenv.env['SPOTIFY_CLIENT_ID'];
      if (clientId == null || clientId.isEmpty) {
        debugPrint('Spotify Client ID not found in .env.local');
        return false;
      }

      final result = await SpotifySdk.connectToSpotifyRemote(
        clientId: clientId,
        redirectUrl: 'helmetapp://callback',
      );
      _isConnected = result;
      return result;
    } on PlatformException catch (e) {
      debugPrint('Spotify connection failed: ${e.message}');
      _isConnected = false;
      return false;
    } on MissingPluginException {
      debugPrint('Spotify SDK not implemented on this platform');
      _isConnected = false;
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await SpotifySdk.disconnect();
      _isConnected = false;
    } on PlatformException catch (e) {
      debugPrint('Spotify disconnect failed: ${e.message}');
    }
  }

  Future<void> play() async {
    if (!_isConnected) await connect();
    if (_isConnected) {
      try {
        await SpotifySdk.resume();
      } on PlatformException catch (e) {
        debugPrint('Spotify play failed: ${e.message}');
      }
    }
  }

  Future<void> pause() async {
    if (!_isConnected) return;
    try {
      await SpotifySdk.pause();
    } on PlatformException catch (e) {
      debugPrint('Spotify pause failed: ${e.message}');
    }
  }

  Future<void> skipNext() async {
    if (!_isConnected) await connect();
    if (_isConnected) {
      try {
        await SpotifySdk.skipNext();
      } on PlatformException catch (e) {
        debugPrint('Spotify skipNext failed: ${e.message}');
      }
    }
  }

  Future<void> skipPrevious() async {
    if (!_isConnected) await connect();
    if (_isConnected) {
      try {
        await SpotifySdk.skipPrevious();
      } on PlatformException catch (e) {
        debugPrint('Spotify skipPrevious failed: ${e.message}');
      }
    }
  }
}
