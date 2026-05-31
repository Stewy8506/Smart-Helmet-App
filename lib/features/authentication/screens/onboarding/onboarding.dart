// Onboarding screen — reserved for a future sprint when authentication is wired up.
// video_player and smooth_page_indicator have been removed from pubspec as they
// are not used anywhere in the active app flow. This file is a stub placeholder.
import 'package:flutter/material.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          'Onboarding — Coming Soon',
          style: TextStyle(color: Colors.white54),
        ),
      ),
    );
  }
}