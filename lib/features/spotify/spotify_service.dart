import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

// --- Data Models ---

class SpotifyPlaylist {
  final String id;
  final String name;
  final String? imageUrl;
  final int trackCount;
  final String uri;

  SpotifyPlaylist({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.trackCount,
    required this.uri,
  });

  factory SpotifyPlaylist.fromJson(Map<String, dynamic> json) {
    String? img;
    final images = json['images'] as List?;
    if (images != null && images.isNotEmpty) {
      img = images.first['url'] as String?;
    }
    return SpotifyPlaylist(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      imageUrl: img,
      trackCount: json['tracks']?['total'] ?? 0,
      uri: json['uri'] ?? '',
    );
  }
}

class SpotifyTrack {
  final String id;
  final String name;
  final String artist;
  final String? albumArt;
  final String uri;

  SpotifyTrack({
    required this.id,
    required this.name,
    required this.artist,
    this.albumArt,
    required this.uri,
  });

  factory SpotifyTrack.fromJson(Map<String, dynamic> json) {
    final artists = json['artists'] as List? ?? [];
    final artistName = artists.isNotEmpty ? artists.first['name'] ?? 'Unknown' : 'Unknown';
    String? art;
    final album = json['album'] as Map<String, dynamic>?;
    if (album != null) {
      final images = album['images'] as List?;
      if (images != null && images.isNotEmpty) {
        art = images.last['url'] as String?; // smallest image
      }
    }
    return SpotifyTrack(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      artist: artistName,
      albumArt: art,
      uri: json['uri'] ?? '',
    );
  }
}

// --- Service ---

class SpotifyService {
  static final SpotifyService instance = SpotifyService._();
  SpotifyService._();

  final ValueNotifier<bool> isConnected = ValueNotifier<bool>(false);
  final ValueNotifier<String> currentTrackName = ValueNotifier<String>('');
  final ValueNotifier<String> currentArtistName = ValueNotifier<String>('');
  final ValueNotifier<bool> isPlaying = ValueNotifier<bool>(false);

  String? _accessToken;

  Future<void> connect() async {
    try {
      final clientId = dotenv.env['SPOTIFY_CLIENT_ID'];
      final redirectUrl = dotenv.env['SPOTIFY_REDIRECT_URI'];

      debugPrint('SpotifyService: connect() called');
      debugPrint('SpotifyService: clientId=$clientId');
      debugPrint('SpotifyService: redirectUrl=$redirectUrl');

      if (clientId == null || clientId.isEmpty || clientId == 'your_spotify_client_id_here') {
        debugPrint('SpotifyService: Client ID is not configured. Aborting.');
        return;
      }

      // First get an access token to trigger the auth flow
      debugPrint('SpotifyService: Getting access token first...');
      try {
        _accessToken = await SpotifySdk.getAccessToken(
          clientId: clientId,
          redirectUrl: redirectUrl ?? '',
          scope: 'app-remote-control,user-modify-playback-state,user-read-playback-state,user-read-currently-playing,playlist-read-private,playlist-read-collaborative',
        ).timeout(const Duration(seconds: 15), onTimeout: () {
          throw TimeoutException('getAccessToken timed out after 15 seconds');
        });
        debugPrint('SpotifyService: Got access token: ${_accessToken!.substring(0, 10)}...');
      } catch (e) {
        debugPrint('SpotifyService: getAccessToken error (non-fatal): $e');
      }

      // Now connect to the remote
      debugPrint('SpotifyService: Calling connectToSpotifyRemote...');
      var result = await SpotifySdk.connectToSpotifyRemote(
        clientId: clientId,
        redirectUrl: redirectUrl ?? '',
        playerName: 'Smart Helmet App',
        scope: 'app-remote-control,user-modify-playback-state,user-read-playback-state,user-read-currently-playing,playlist-read-private,playlist-read-collaborative',
      ).timeout(const Duration(seconds: 15), onTimeout: () {
        throw TimeoutException('connectToSpotifyRemote timed out after 15 seconds');
      });

      debugPrint('SpotifyService: connectToSpotifyRemote returned: $result');
      if (result) {
        isConnected.value = true;
        _listenToPlayerState();
      }
    } catch (e, stackTrace) {
      debugPrint('SpotifyService: connection error: $e');
      debugPrint('SpotifyService: stackTrace: $stackTrace');
      isConnected.value = false;
    }
  }

  void _listenToPlayerState() {
    SpotifySdk.subscribePlayerState().listen((state) {
      if (state.track != null) {
        currentTrackName.value = state.track?.name ?? '';
        currentArtistName.value = state.track?.artist.name ?? '';
      }
      isPlaying.value = !state.isPaused;
    });
  }

  Future<void> disconnect() async {
    try {
      await SpotifySdk.disconnect();
      isConnected.value = false;
      currentTrackName.value = '';
      currentArtistName.value = '';
      isPlaying.value = false;
      _accessToken = null;
    } catch (e) {
      debugPrint('Spotify disconnect error: $e');
    }
  }

  // --- Playback ---

  Future<void> play() async {
    if (!isConnected.value) await connect();
    if (isConnected.value) {
      try {
        // Try resuming current playback first
        await SpotifySdk.resume();
      } catch (e) {
        debugPrint('SpotifyService: resume failed ($e), starting Liked Songs...');
        try {
          // Nothing in queue — start the user's Liked Songs (shuffled)
          await SpotifySdk.play(spotifyUri: 'spotify:user:spotify:collection');
          await SpotifySdk.setShuffle(shuffle: true);
        } catch (e2) {
          debugPrint('SpotifyService: play Liked Songs also failed: $e2');
        }
      }
    }
  }

  Future<void> playUri(String spotifyUri) async {
    if (!isConnected.value) await connect();
    if (isConnected.value) {
      try {
        await SpotifySdk.play(spotifyUri: spotifyUri);
      } catch (e) {
        debugPrint('SpotifyService: playUri error: $e');
      }
    }
  }

  Future<void> pause() async {
    if (isConnected.value) {
      try {
        await SpotifySdk.pause();
      } catch (e) {
        debugPrint('Spotify pause error: $e');
      }
    }
  }

  Future<void> skipToNext() async {
    if (isConnected.value) {
      try {
        await SpotifySdk.skipNext();
      } catch (e) {
        debugPrint('Spotify skipNext error: $e');
      }
    }
  }

  Future<void> skipToPrevious() async {
    if (isConnected.value) {
      try {
        await SpotifySdk.skipPrevious();
      } catch (e) {
        debugPrint('Spotify skipPrevious error: $e');
      }
    }
  }

  // --- Web API ---

  Future<List<SpotifyPlaylist>> fetchPlaylists() async {
    if (_accessToken == null) return [];
    try {
      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/me/playlists?limit=20'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List? ?? [];
        return items.map((e) => SpotifyPlaylist.fromJson(e)).toList();
      } else {
        debugPrint('SpotifyService: fetchPlaylists status=${response.statusCode}');
      }
    } catch (e) {
      debugPrint('SpotifyService: fetchPlaylists error: $e');
    }
    return [];
  }

  Future<List<SpotifyTrack>> searchTracks(String query) async {
    if (_accessToken == null || query.trim().isEmpty) return [];
    try {
      final encoded = Uri.encodeComponent(query);
      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/search?q=$encoded&type=track&limit=15'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['tracks']?['items'] as List? ?? [];
        return items.map((e) => SpotifyTrack.fromJson(e)).toList();
      } else {
        debugPrint('SpotifyService: searchTracks status=${response.statusCode}');
      }
    } catch (e) {
      debugPrint('SpotifyService: searchTracks error: $e');
    }
    return [];
  }
}
