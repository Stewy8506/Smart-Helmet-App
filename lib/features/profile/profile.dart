import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import 'package:helmet_app/common/sizes.dart';
import 'package:helmet_app/features/grid_screen/grid_screen.dart';
import 'package:helmet_app/features/dashboard/dashboard.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedIndex = 2;
  bool _isSwiping = false;

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
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: TSizes.spaceBtwSections),

                        Text(
                          "Your Profile.",
                          style: GoogleFonts.bitcountPropSingle(
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                            fontSize: 38,
                          ),
                        ),

                        const SizedBox(height: TSizes.spaceBtwSections + 20),

                        // Avatar
                        Center(
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.white10,
                            child: Icon(Icons.person, size: 60, color: Colors.white70),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Center(
                          child: Text(
                            "Anuvab Das",
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),

                        Center(
                          child: Text(
                            "Rider • Explorer",
                            style: GoogleFonts.montserrat(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ),

                        const SizedBox(height: TSizes.spaceBtwSections),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: const [
                            _ProfileStat(label: "124", sub: "Trips"),
                            _ProfileStat(label: "1.2k", sub: "KM"),
                            _ProfileStat(label: "87%", sub: "Safety"),
                          ],
                        ),

                        const SizedBox(height: TSizes.spaceBtwSections),

                        _ProfileCard(
                          icon: Icons.settings,
                          title: "Settings",
                        ),
                        _ProfileCard(
                          icon: Icons.history,
                          title: "Ride History",
                        ),
                        _ProfileCard(
                          icon: Icons.logout,
                          title: "Logout",
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Navbar
          LiquidGlassLayer(
            settings: const LiquidGlassSettings(
              thickness: 20,
              blur: 2,
              glassColor: Colors.black26,
            ),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment(0, 0.95),
                  child: LiquidGlass(
                    shape: LiquidRoundedRectangle(borderRadius: 30),
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTapDown: (_) {
                        _isSwiping = false;
                      },
                      onHorizontalDragUpdate: (details) {
                        if (_isSwiping) return;

                        if (details.delta.dx > 5 && _selectedIndex < 2) {
                          _isSwiping = true;
                          HapticFeedback.lightImpact();
                          setState(() {
                            _selectedIndex++;
                            if (_selectedIndex == 1) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const GridScreen()),
                              );
                            } else if (_selectedIndex == 2) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const ProfileScreen()),
                              );
                            }
                          });
                        } else if (details.delta.dx < -5 && _selectedIndex > 0) {
                          _isSwiping = true;
                          HapticFeedback.lightImpact();
                          setState(() {
                            _selectedIndex--;
                            if (_selectedIndex == 0) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const DashboardScreen()),
                              );
                            } else if (_selectedIndex == 1) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const GridScreen()),
                              );
                            }
                          });
                        }
                      },
                      onHorizontalDragEnd: (_) {
                        _isSwiping = false;
                      },
                      child: SizedBox(
                        width: 180,
                        height: 55,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedAlign(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutBack,
                              alignment: Alignment(
                                _selectedIndex == 0
                                    ? -0.93
                                    : _selectedIndex == 1
                                    ? 0
                                    : 0.93,
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
                                    setState(() => _selectedIndex = 0);
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (_) => const DashboardScreen()),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: AnimatedScale(
                                      scale: _selectedIndex == 0 ? 1.2 : 0.8,
                                      duration: const Duration(milliseconds: 200),
                                      curve: Curves.easeOutBack,
                                      child: Icon(
                                        Icons.directions_bike,
                                        color: _selectedIndex == 0
                                            ? Colors.white
                                            : Colors.white54,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 23),
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    setState(() => _selectedIndex = 1);
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (_) => const GridScreen()),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: AnimatedScale(
                                      scale: _selectedIndex == 1 ? 1.2 : 0.8,
                                      duration: const Duration(milliseconds: 200),
                                      curve: Curves.easeOutBack,
                                      child: Icon(
                                        Icons.explore_outlined,
                                        color: _selectedIndex == 1
                                            ? Colors.white
                                            : Colors.white54,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 23),
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    setState(() => _selectedIndex = 2);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: AnimatedScale(
                                      scale: _selectedIndex == 2 ? 1.2 : 0.8,
                                      duration: const Duration(milliseconds: 200),
                                      curve: Curves.easeOutBack,
                                      child: Icon(
                                        Icons.person_outline,
                                        color: _selectedIndex == 2
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String label;
  final String sub;

  const _ProfileStat({required this.label, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        Text(sub,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final IconData icon;
  final String title;

  const _ProfileCard({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}