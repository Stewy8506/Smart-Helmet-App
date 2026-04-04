

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Title + Back
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Settings.",
                          style: GoogleFonts.bitcountPropSingle(
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                            fontSize: 38,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    _SettingsTile(
                      icon: Icons.bluetooth,
                      title: "Device Connection",
                    ),
                    _SettingsTile(
                      icon: Icons.music_note,
                      title: "Music Preferences",
                    ),
                    _SettingsTile(
                      icon: Icons.map,
                      title: "Navigation Settings",
                    ),
                    _SettingsTile(
                      icon: Icons.notifications,
                      title: "Notifications",
                    ),
                    _SettingsTile(
                      icon: Icons.security,
                      title: "Privacy & Security",
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Glass Bar (optional aesthetic consistency)
          LiquidGlassLayer(
            settings: const LiquidGlassSettings(
              thickness: 20,
              blur: 2,
              glassColor: Colors.black26,
            ),
            child: const SizedBox(),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SettingsTile({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(25),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70),
            const SizedBox(width: 14),
            Text(
              title,
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
          ],
        ),
      ),
    );
  }
}