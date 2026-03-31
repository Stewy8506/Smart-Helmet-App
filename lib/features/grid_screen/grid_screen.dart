import 'package:flutter/material.dart';
import 'package:helmet_app/features/navigation/maps.dart';
import 'package:helmet_app/features/navigation/util/background.dart';

class GridScreen extends StatelessWidget {
  const GridScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              // Maps Widget (rectangular + freely positioned)
              Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: double.infinity,
                  height: 180,
                child: _MapsPreviewTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 400),
                        reverseTransitionDuration: const Duration(milliseconds: 300),
                        pageBuilder: (context, animation, secondaryAnimation) => const MapsScreen(),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          final curved = CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeInOutCubic,
                          );

                          return FadeTransition(
                            opacity: curved,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.05),
                                end: Offset.zero,
                              ).animate(curved),
                              child: child,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                ),
              ),

              // Calls Widget
              Align(
                alignment: Alignment.bottomLeft,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.45,
                  height: 150,
                  child: _GridTile(
                    title: "Calls",
                    icon: Icons.call,
                    color: Colors.green,
                    onTap: () {},
                  ),
                ),
              ),

              // Music Widget
              Align(
                alignment: Alignment.bottomRight,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.45,
                  height: 150,
                  child: _GridTile(
                    title: "Music",
                    icon: Icons.music_note,
                    color: Colors.deepPurple,
                    onTap: () {},
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _GridTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.black,
          border: Border.all(color: Colors.blueAccent.withAlpha(120)),
        ),
        child: Stack(
          children: [
            // Real map preview using shared background
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: IgnorePointer(
                child: MyBackgroundContent(isPreview: true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}