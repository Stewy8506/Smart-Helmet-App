import 'package:flutter/material.dart';

class MyBackgroundContent extends StatelessWidget {
  const MyBackgroundContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,

      // 🔥 Base black background
      color: Colors.black,

      // 👇 Optional styling layer (subtle depth)
      child: Stack(
        children: [
          // Soft gradient overlay (makes UI look premium)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF000000),
                  Color(0xFF0A0A0A),
                  Color(0xFF111111),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Optional noise / vignette feel
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(51),
            ),
          ),
        ],
      ),
    );
  }
}