import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:helmet_app/features/navigation/maps.dart';
import 'package:helmet_app/features/navigation/util/background.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:url_launcher/url_launcher.dart';

class GridScreen extends StatelessWidget {
  const GridScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Stack(
            children: [
              Align(
                alignment: Alignment(0, 0.9),
                child: SizedBox(
                  width: 360,
                  height: 450,
                  child: _MapsPreviewTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MapsScreen()),
                      );
                    },
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Stack(
                    children: [
                      // Calls Widget
                      Align(
                        alignment: Alignment.topRight,
                        child: _CallsWidget(
                          width: MediaQuery.of(context).size.width * 0.45,
                          height: 300,
                        ),
                      ),

                      // Music Widget
                      Align(
                        alignment: Alignment.topLeft,
                        child: _GridTile(
                          title: "Music",
                          icon: Icons.music_note,
                          color: Colors.deepPurple,
                          width: MediaQuery.of(context).size.width * 0.45,
                          height: 150,
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 👇 MOVE NAVBAR INSIDE LiquidGlassLayer
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: _BottomNavBar(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GridTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double? width;
  final double? height;

  const _GridTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: height,
        child: Container(
          decoration: BoxDecoration(
            color: color.withAlpha(39),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withAlpha(102)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
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
    } else {
      print('Could not launch dialer');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    print("LOAD CONTACTS START");

    final permission = await FlutterContacts.requestPermission(readonly: true);
    print("Permission: $permission");

    if (!permission) {
      print("Permission denied");
      return;
    }

    final fetched = await FlutterContacts.getContacts(
      withProperties: true,
      withPhoto: true,
      withThumbnail: true,
    );

    print("Fetched contacts: ${fetched.length}");

    if (!mounted) {
      print("Widget not mounted");
      return;
    }

    final allowedNames = [
      "Sreyashi",
      "Sagnik RCCIIT",
      "Anwita",
      "Subhrodip RCCIIT",
      "mum",
    ];

    final priorityOrder = [
      "Sreyashi",
      "Sagnik RCCIIT",
      "Anwita",
    ];

    setState(() {
      contacts = fetched
          .where((c) => c.displayName.trim().isNotEmpty)
          .where((c) => allowedNames.any((name) =>
              c.displayName.trim().toLowerCase() == name.toLowerCase()))
          .toList()
        ..sort((a, b) {
          int aIndex = priorityOrder.indexWhere((name) =>
              a.displayName.trim().toLowerCase() == name.toLowerCase());
          int bIndex = priorityOrder.indexWhere((name) =>
              b.displayName.trim().toLowerCase() == name.toLowerCase());

          if (aIndex == -1) aIndex = 999;
          if (bIndex == -1) bIndex = 999;

          return aIndex.compareTo(bIndex);
        });
    });

    print("Contacts set: ${contacts.length}");
  }

  @override
  Widget build(BuildContext context) {
    if (contacts.isEmpty) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: const Center(
          child: Text(
            "No contacts found",
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    final favorites = contacts.take(3).toList();
    final recents = contacts.length > 3
        ? contacts.sublist(3, contacts.length > 8 ? 8 : contacts.length)
        : [];

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(288),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withAlpha((0.15 * 255).toInt())),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Calls",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Favorites (top 3)
            ...favorites.map((contact) {
              final imageData = contact.photoOrThumbnail;

              return GestureDetector(
                onTap: () => _callContact(contact),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.grey[800],
                        backgroundImage: imageData != null
                            ? MemoryImage(imageData)
                            : null,
                        child: imageData == null
                            ? Text(
                                contact.displayName.isNotEmpty ? contact.displayName[0] : "?",
                                style: const TextStyle(color: Colors.white),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          contact.displayName,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
                  final imageData = contact.photoOrThumbnail;

                  return GestureDetector(
                    onTap: () => _callContact(contact),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.grey[800],
                            backgroundImage: imageData != null
                                ? MemoryImage(imageData)
                                : null,
                            child: imageData == null
                                ? Text(
                                    contact.displayName.isNotEmpty ? contact.displayName[0] : "?",
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              contact.displayName,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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
                  child: MyBackgroundContent(
                    isPreview: true,
                  ),
                ),
              ),

              // 🔥 GLASS OVERLAY ON TOP
              // Removed LiquidGlass overlay as per instructions
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

    if (details.primaryVelocity! < -200) {
      // swipe left → go backwards
      if (_currentIndex > 0) {
        setState(() => _currentIndex--);
      }
    } else if (details.primaryVelocity! > 200) {
      // swipe right → go forward
      if (_currentIndex < 2) {
        setState(() => _currentIndex++);
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
              color: Colors.black.withAlpha((0.2 * 255).toInt()),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withAlpha((0.05 * 255).toInt())),
            ),
            width: 220,
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _NavItem(
                  icon: Icons.grid_view,
                  selected: _currentIndex == 0,
                  onTap: () {
                    setState(() => _currentIndex = 0);
                  },
                ),
                _NavItem(
                  icon: Icons.home,
                  selected: _currentIndex == 1,
                  onTap: () {
                    setState(() => _currentIndex = 1);
                    // TODO: Navigate to home.dart
                  },
                ),
                _NavItem(
                  icon: Icons.person,
                  selected: _currentIndex == 2,
                  onTap: () {
                    setState(() => _currentIndex = 2);
                    // TODO: Navigate to profile.dart
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withAlpha(40) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          boxShadow: selected? [
            BoxShadow(
              color: Colors.white.withAlpha(20),
              blurRadius: 10,
              spreadRadius: 2
            )
          ] : [],
        ),
        child: Icon(
          icon,
          color: selected ? Colors.white : Colors.white54,
          size: selected ? 30 : 25,
        ),
      ),
    );
  }
}