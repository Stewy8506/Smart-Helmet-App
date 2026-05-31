import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalAudioService {
  static final LocalAudioService instance = LocalAudioService._();

  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _player = AudioPlayer();

  final ValueNotifier<SongModel?> currentSong = ValueNotifier(null);
  
  List<SongModel> _songs = [];
  bool _isInitialized = false;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  LocalAudioService._() {
    _player.currentIndexStream.listen((index) {
      if (index != null && index < _songs.length) {
        currentSong.value = _songs[index];
        _saveLastPlayedIndex(index);
      }
    });
  }

  Future<bool> requestPermissions() async {
    PermissionStatus status;
    if (defaultTargetPlatform == TargetPlatform.android) {
       // Android 13+ requires photos/audio permission instead of storage
       status = await Permission.audio.request();
       if (status.isDenied) {
          status = await Permission.storage.request();
       }
    } else {
       status = await Permission.storage.request();
    }
    return status.isGranted;
  }

  Future<void> loadSongs() async {
    if (_isInitialized) return;
    
    bool hasPermission = await _audioQuery.permissionsStatus();
    if (!hasPermission) {
      hasPermission = await requestPermissions();
    }
    if (!hasPermission) {
      debugPrint("Storage permissions denied");
      return;
    }

    _songs = await _audioQuery.querySongs(
      sortType: null,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    if (_songs.isNotEmpty) {
      final playlist = ConcatenatingAudioSource(
        children: _songs.map((song) => AudioSource.uri(Uri.parse(song.data))).toList(),
      );
      
      await _player.setAudioSource(playlist);
      _isInitialized = true;

      // Restore last played index
      final prefs = await SharedPreferences.getInstance();
      final lastIndex = prefs.getInt('last_played_index') ?? 0;
      if (lastIndex < _songs.length) {
        await _player.seek(Duration.zero, index: lastIndex);
        currentSong.value = _songs[lastIndex];
      } else {
        currentSong.value = _songs.first;
      }
    }
  }

  Future<void> _saveLastPlayedIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_played_index', index);
  }

  Future<void> play() async {
    if (!_isInitialized) await loadSongs();
    if (_songs.isNotEmpty) {
      await _player.play();
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> skipToNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    } else {
       await _player.seek(Duration.zero, index: 0); // Loop back to start
    }
  }

  Future<void> skipToPrevious() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    } else {
      await _player.seek(Duration.zero);
    }
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
  }

  void dispose() {
    _player.dispose();
  }
}
