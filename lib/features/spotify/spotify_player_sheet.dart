import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:helmet_app/features/spotify/spotify_service.dart';


class SpotifyPlayerSheet extends StatefulWidget {
  const SpotifyPlayerSheet({super.key});

  @override
  State<SpotifyPlayerSheet> createState() => _SpotifyPlayerSheetState();
}

class _SpotifyPlayerSheetState extends State<SpotifyPlayerSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<SpotifyPlaylist> _playlists = [];
  List<SpotifyTrack> _searchResults = [];
  bool _loadingPlaylists = true;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPlaylists();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadPlaylists() async {
    final playlists = await SpotifyService.instance.fetchPlaylists();
    if (mounted) {
      setState(() {
        _playlists = playlists;
        _loadingPlaylists = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _searching = true);
      final results = await SpotifyService.instance.searchTracks(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _searching = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF121212),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white30,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Now Playing bar
              _buildNowPlaying(),

              const Divider(color: Colors.white12, height: 1),

              // Tab bar
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.greenAccent,
                labelColor: Colors.greenAccent,
                unselectedLabelColor: Colors.white54,
                labelStyle: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 14),
                tabs: const [
                  Tab(text: 'Playlists'),
                  Tab(text: 'Search'),
                ],
              ),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPlaylistsTab(scrollController),
                    _buildSearchTab(scrollController),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNowPlaying() {
    return ValueListenableBuilder<String>(
      valueListenable: SpotifyService.instance.currentTrackName,
      builder: (context, trackName, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: SpotifyService.instance.isPlaying,
          builder: (context, isPlaying, _) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Album art placeholder
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.music_note, color: Colors.greenAccent, size: 24),
                  ),
                  const SizedBox(width: 12),

                  // Track info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trackName.isEmpty ? 'Not Playing' : trackName,
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        ValueListenableBuilder<String>(
                          valueListenable: SpotifyService.instance.currentArtistName,
                          builder: (context, artist, _) {
                            return Text(
                              artist.isEmpty ? '—' : artist,
                              style: GoogleFonts.montserrat(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Controls
                  IconButton(
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      await SpotifyService.instance.skipToPrevious();
                    },
                    icon: const Icon(Icons.skip_previous, color: Colors.white70, size: 22),
                    visualDensity: VisualDensity.compact,
                  ),
                  GestureDetector(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                        if (isPlaying) {
                          await SpotifyService.instance.pause();
                        } else {
                          await SpotifyService.instance.play();
                        }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.greenAccent.withAlpha(40),
                      ),
                      child: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.greenAccent,
                        size: 24,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      await SpotifyService.instance.skipToNext();
                    },
                    icon: const Icon(Icons.skip_next, color: Colors.white70, size: 22),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlaylistsTab(ScrollController scrollController) {
    if (_loadingPlaylists) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.greenAccent),
      );
    }

    if (_playlists.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.playlist_play, color: Colors.white38, size: 48),
            const SizedBox(height: 12),
            Text(
              'No playlists found',
              style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _playlists.length,
      itemBuilder: (context, index) {
        final playlist = _playlists[index];
        return _buildPlaylistTile(playlist);
      },
    );
  }

  Widget _buildPlaylistTile(SpotifyPlaylist playlist) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: playlist.imageUrl != null
            ? Image.network(
                playlist.imageUrl!,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _playlistPlaceholder(),
              )
            : _playlistPlaceholder(),
      ),
      title: Text(
        playlist.name,
        style: GoogleFonts.montserrat(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${playlist.trackCount} tracks',
        style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 12),
      ),
      trailing: const Icon(Icons.play_circle_outline, color: Colors.greenAccent, size: 28),
      onTap: () async {
        HapticFeedback.lightImpact();
        await SpotifyService.instance.playUri(playlist.uri);
      },
    );
  }

  Widget _playlistPlaceholder() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.queue_music, color: Colors.greenAccent, size: 24),
    );
  }

  Widget _buildSearchTab(ScrollController scrollController) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: GoogleFonts.montserrat(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search songs, artists...',
              hintStyle: GoogleFonts.montserrat(color: Colors.white38),
              prefixIcon: const Icon(Icons.search, color: Colors.white38),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white38),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchResults = []);
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withAlpha(15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),

        // Results
        Expanded(
          child: _searching
              ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
              : _searchResults.isEmpty
                  ? Center(
                      child: Text(
                        _searchController.text.isEmpty
                            ? 'Search for a song to play'
                            : 'No results found',
                        style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 14),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final track = _searchResults[index];
                        return _buildTrackTile(track);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildTrackTile(SpotifyTrack track) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: track.albumArt != null
            ? Image.network(
                track.albumArt!,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _trackPlaceholder(),
              )
            : _trackPlaceholder(),
      ),
      title: Text(
        track.name,
        style: GoogleFonts.montserrat(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        track.artist,
        style: GoogleFonts.montserrat(color: Colors.white54, fontSize: 11),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.play_circle_outline, color: Colors.greenAccent, size: 24),
      onTap: () async {
        HapticFeedback.lightImpact();
        await SpotifyService.instance.playUri(track.uri);
      },
    );
  }

  Widget _trackPlaceholder() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.music_note, color: Colors.greenAccent, size: 20),
    );
  }
}
