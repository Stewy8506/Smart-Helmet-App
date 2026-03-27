import 'package:flutter/material.dart';
import 'package:spotify_sdk/spotify_sdk.dart';

class SpotifyWidget extends StatefulWidget {
  const SpotifyWidget({super.key});

  @override
  State<SpotifyWidget> createState() => _SpotifyWidgetState();
}

class _SpotifyWidgetState extends State<SpotifyWidget> {
  bool isPlaying = false;
  String trackName = "Not Playing";
  String artist = "";
  String imageUrl = "";

  @override
  void initState() {
    super.initState();
    connect();
    listenToPlayerState();
  }

  Future<void> connect() async {
    try {
      await SpotifySdk.connectToSpotifyRemote(
        clientId: "YOUR_CLIENT_ID",
        redirectUrl: "helmetapp://callback",
      );
    } catch (e) {
      print("Connection error: $e");
    }
  }

  void listenToPlayerState() {
    SpotifySdk.subscribePlayerState().listen((state) {
      setState(() {
        isPlaying = !state.isPaused;
        trackName = state.track?.name ?? "";
        artist = state.track?.artist.name ?? "";

        // album art
        imageUrl = state.track?.imageUri.raw ?? "";
      });
    });
  }

  Future<void> play() async {
    await SpotifySdk.resume();
  }

  Future<void> pause() async {
    await SpotifySdk.pause();
  }

  Future<void> next() async {
    await SpotifySdk.skipNext();
  }

  Future<void> previous() async {
    await SpotifySdk.skipPrevious();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Album Image
          imageUrl.isNotEmpty
              ? Image.network(imageUrl, height: 120)
              : const Icon(Icons.music_note, size: 80),

          const SizedBox(height: 10),

          // Track info
          Text(trackName, style: const TextStyle(color: Colors.white)),
          Text(artist, style: const TextStyle(color: Colors.white54)),

          const SizedBox(height: 10),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(onPressed: previous, icon: const Icon(Icons.skip_previous)),
              IconButton(
                onPressed: isPlaying ? pause : play,
                icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
              ),
              IconButton(onPressed: next, icon: const Icon(Icons.skip_next)),
            ],
          ),
        ],
      ),
    );
  }
}
