import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:helmet_app/features/spotify/spotify_service.dart';
import 'package:helmet_app/features/spotify/spotify_player_sheet.dart';
import 'package:helmet_app/common/sizes.dart';
import 'package:helmet_app/features/navigation/maps.dart';
import 'package:helmet_app/features/dashboard/dashboard.dart';
import 'package:helmet_app/features/navigation/util/background.dart';
import 'package:helmet_app/features/profile/profile.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:helmet_app/features/settings/settings_service.dart';
import 'package:helmet_app/features/voice_assistant/widgets/voice_fab.dart';
import 'package:google_fonts/google_fonts.dart';


class GridScreen extends StatelessWidget {
  const GridScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.3),
                  radius: 0.45,
                  colors: [
                    Color.fromARGB(255, 45, 45, 45),
                    Color.fromARGB(255, 15, 15, 15),
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment(0, 0.7),
                        child: SizedBox(
                          width: 345,
                          height: 400,
                          child: _MapsPreviewTile(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MapsScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // Calls + Music
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.topRight,
                              child: Transform.translate(
                                offset: const Offset(
                                  24,
                                  0,
                                ), // adjust this value to move more/less right
                                child: _CallsWidget(
                                  width:
                                      MediaQuery.of(context).size.width * 0.455,
                                  height: 300,
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.topLeft,
                              child: Transform.translate(
                                offset: const Offset(
                                  -21,
                                  0,
                                ), // tweak value as needed
                                child: _MusicWidget(
                                  width:
                                      MediaQuery.of(context).size.width * 0.455,
                                  height: 180,
                                ),
                              ),
                            ),
                            // Battery widget below music
                            Align(
                              alignment: Alignment.topLeft,
                              child: Transform.translate(
                                offset: const Offset(
                                  -21,
                                  190,
                                ), // position below music widget
                                child: _BatteryWidget(
                                  width:
                                      MediaQuery.of(context).size.width * 0.455,
                                  height: 110,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: 85,
            child: const VoiceFAB(),
          ),
          Positioned(
            bottom: 18,
            left: 0,
            right: 0,
            child: Center(child: _BottomNavBar()),
          ),
        ],
      ),
    );
  }
}

class _CallsWidget extends StatefulWidget {
  final double width;
  final double height;

  const _CallsWidget({required this.width, required this.height});

  @override
  State<_CallsWidget> createState() => _CallsWidgetState();
}

class _CallsWidgetState extends State<_CallsWidget> {
  List<Contact> contacts = [];

  Future<void> _callContact(Contact contact) async {
    if (contact.phones.isEmpty) return;

    final number = contact.phones.first.number;
    final uri = Uri.parse('tel:$number');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  String _normalizePhone(String phone) =>
      phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');

  Future<void> _loadContacts() async {
    final whitelist = SettingsService.instance.contactWhitelist;
    if (whitelist.isEmpty) {
      // No contacts configured — show empty state without requesting permissions
      if (mounted) setState(() {});
      return;
    }

    final permission = await FlutterContacts.permissions.request(PermissionType.read);
    if (permission != PermissionStatus.granted) return;

    final fetched = await FlutterContacts.getAll(
      properties: {ContactProperty.name, ContactProperty.phone, ContactProperty.photoThumbnail},
    );

    if (!mounted) return;

    // Match by normalized phone number — reliable even if names differ
    final allowedPhones = whitelist.map((c) => _normalizePhone(c.phone)).toSet();

    setState(() {
      contacts = fetched
          .where((c) => c.phones.isNotEmpty)
          .where((c) => allowedPhones.contains(_normalizePhone(c.phones.first.number)))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final whitelist = SettingsService.instance.contactWhitelist;
    if (contacts.isEmpty) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Center(
          child: Text(
            whitelist.isEmpty
                ? "Add contacts in\nSettings → Emergency Contacts"
                : "No matching contacts found",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ),
      );
    }

    final favorites = contacts.take(1).toList();
    final recents = contacts.length > 1 ? contacts.skip(1).toList() : [];

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF121212).withAlpha((0.55 * 255).toInt()),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withAlpha((0.3 * 255).toInt())),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Calls",
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),

            // Favorites (top 3)
            ...favorites.map((contact) {
              final imageData = contact.photo?.thumbnail;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _callContact(contact),
                  child: AnimatedScale(
                    scale: 1.0,
                    duration: const Duration(milliseconds: 100),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey[800],
                            backgroundImage: imageData != null
                                ? MemoryImage(imageData)
                                : null,
                            child: imageData == null
                                ? Text(
                                    (contact.displayName ?? "").isNotEmpty
                                        ? (contact.displayName ?? "")[0]
                                        : "?",
                                    style: const TextStyle(color: Colors.white),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              contact.displayName ?? "",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 12),

            const Text(
              "Recent",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 6),

            Expanded(
              child: ListView.builder(
                itemCount: recents.length,
                itemBuilder: (context, index) {
                  final contact = recents[index];
                  final imageData = contact.photo?.thumbnail;

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _callContact(contact),
                      child: AnimatedScale(
                        scale: 1.0,
                        duration: const Duration(milliseconds: 100),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.grey[800],
                                backgroundImage: imageData != null
                                    ? MemoryImage(imageData)
                                    : null,
                                child: imageData == null
                                    ? Text(
                                        (contact.displayName ?? "").isNotEmpty
                                            ? (contact.displayName ?? "")[0]
                                            : "?",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  contact.displayName ?? "",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapsPreviewTile extends StatelessWidget {
  final VoidCallback onTap;

  const _MapsPreviewTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: "mapHero",
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // 🔥 MAP OUTSIDE GLASS EFFECT (fix layering)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: IgnorePointer(
                  child: MyBackgroundContent(isPreview: true),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavBar extends StatefulWidget {
  @override
  State<_BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<_BottomNavBar> {
  int _currentIndex = 1;

  void _onSwipe(DragEndDetails details) {
    if (details.primaryVelocity == null) return;

    // Add haptic feedback on swipe
    HapticFeedback.lightImpact();

    if (details.primaryVelocity! < -200) {
      // swipe left → go backward
      if (_currentIndex > 0) {
        setState(() => _currentIndex--);

        if (_currentIndex == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        } else if (_currentIndex == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          );
        }
      }
    } else if (details.primaryVelocity! > 200) {
      // swipe right → go forward
      if (_currentIndex < 2) {
        setState(() => _currentIndex++);

        if (_currentIndex == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        } else if (_currentIndex == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: _onSwipe,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2.3, sigmaY: 2.3),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F0F),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                // Inner shadow (top-left light)
                BoxShadow(
                  color: Colors.white.withAlpha(15),
                  offset: const Offset(-2, -2),
                  blurRadius: 6,
                  spreadRadius: -2,
                ),
                // Inner shadow (bottom-right dark)
                BoxShadow(
                  color: Colors.black.withAlpha(200),
                  offset: const Offset(3, 3),
                  blurRadius: 8,
                  spreadRadius: -2,
                ),
              ],
            ),
            width: 180,
            height: 55,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedAlign(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutBack,
                  alignment: Alignment(
                    _currentIndex == 0
                        ? -1
                        : _currentIndex == 1
                        ? 0
                        : 1,
                    0,
                  ),
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(39),
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _currentIndex = 0);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DashboardScreen(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: AnimatedScale(
                          scale: _currentIndex == 0 ? 1.2 : 0.8,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutBack,
                          child: Icon(
                            Icons.directions_bike,
                            color: _currentIndex == 0
                                ? Colors.white
                                : Colors.white54,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 25),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _currentIndex = 1);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: AnimatedScale(
                          scale: _currentIndex == 1 ? 1.2 : 0.8,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutBack,
                          child: Icon(
                            Icons.explore_outlined,
                            color: _currentIndex == 1
                                ? Colors.white
                                : Colors.white54,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 25),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _currentIndex = 2);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: AnimatedScale(
                          scale: _currentIndex == 2 ? 1.2 : 0.8,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutBack,
                          child: Icon(
                            Icons.person_outline,
                            color: _currentIndex == 2
                                ? Colors.white
                                : Colors.white54,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MusicWidget extends StatefulWidget {
  final double width;
  final double height;

  const _MusicWidget({required this.width, required this.height});

  @override
  State<_MusicWidget> createState() => _MusicWidgetState();
}

class _MusicWidgetState extends State<_MusicWidget> {
  Widget _buildDisconnectedUI() {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF121212).withAlpha((0.55 * 255).toInt()),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withAlpha((0.2 * 255).toInt())),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Spotify",
              style: GoogleFonts.montserrat(
                color: Colors.greenAccent,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: () => SpotifyService.instance.connect(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent,
                  foregroundColor: Colors.black,
                ),
                child: const Text("Connect"),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerUI(String trackName, String artistName, bool isPlaying) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF121212).withAlpha((0.55 * 255).toInt()),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withAlpha((0.2 * 255).toInt())),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Spotify",
              style: GoogleFonts.montserrat(
                color: Colors.greenAccent,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.music_note, color: Colors.greenAccent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ScrollingText(
                        text: trackName.isEmpty ? "Not Playing" : trackName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        artistName.isEmpty ? "Unknown" : artistName,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Expanded(
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        await SpotifyService.instance.skipToPrevious();
                      },
                      icon: const Icon(
                        Icons.skip_previous,
                        color: Colors.white70,
                      ),
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
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.greenAccent.withAlpha(50),
                        ),
                        child: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.greenAccent,
                          size: 28,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        await SpotifyService.instance.skipToNext();
                      },
                      icon: const Icon(Icons.skip_next, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (SpotifyService.instance.isConnected.value) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const SpotifyPlayerSheet(),
          );
        }
      },
      child: ValueListenableBuilder<bool>(
        valueListenable: SpotifyService.instance.isConnected,
        builder: (context, isConnected, child) {
          if (!isConnected) {
            return _buildDisconnectedUI();
          }

          return ValueListenableBuilder<String>(
            valueListenable: SpotifyService.instance.currentTrackName,
            builder: (context, trackName, _) {
              return ValueListenableBuilder<String>(
                valueListenable: SpotifyService.instance.currentArtistName,
                builder: (context, artistName, _) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: SpotifyService.instance.isPlaying,
                    builder: (context, isPlaying, _) {
                      return _buildPlayerUI(trackName, artistName, isPlaying);
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// --- Battery Widget ---
class _BatteryWidget extends StatelessWidget {
  final double width;
  final double height;

  const _BatteryWidget({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF121212).withAlpha((0.55 * 255).toInt()),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withAlpha((0.2 * 255).toInt())),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Battery",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: TSizes.spaceBtwItems),

            // Phone Battery
            Row(
              children: [
                const Icon(Icons.phone_iphone, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                const Text(
                  "Phone",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const Spacer(),
                const Text(
                  "78%",
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Helmet Battery (always full + charging)
            Row(
              children: [
                const Icon(
                  Icons.safety_check,
                  color: Colors.greenAccent,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Text(
                  "Helmet",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const Spacer(),
                Row(
                  children: const [
                    SizedBox(width: 8),
                    Icon(Icons.bolt, color: Colors.greenAccent, size: 14),
                    SizedBox(width: 4),
                    Text(
                      "100%",
                      style: TextStyle(color: Colors.greenAccent, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScrollingText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const _ScrollingText({
    required this.text,
    required this.style,
  });

  @override
  State<_ScrollingText> createState() => _ScrollingTextState();
}

class _ScrollingTextState extends State<_ScrollingText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textPainter = TextPainter(
            text: TextSpan(text: widget.text, style: widget.style),
            maxLines: 1,
            textDirection: TextDirection.ltr,
          )..layout();

          final textWidth = textPainter.width;
          final boxWidth = constraints.maxWidth;

          // If text fits → no animation
          if (textWidth <= boxWidth) {
            return Text(
              widget.text,
              style: widget.style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          }

          const gap = 40.0;
          final totalScrollWidth = textWidth + gap;

          return AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final dx = (1 - _controller.value) * totalScrollWidth * -1;
              return Transform.translate(
                offset: Offset(dx, 0),
                child: child,
              );
            },
            child: Row(
              children: [
                Text(
                  widget.text,
                  style: widget.style,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                ),
                const SizedBox(width: 40),
                Text(
                  widget.text,
                  style: widget.style,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}