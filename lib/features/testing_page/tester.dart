import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import 'package:helmet_app/features/testing_page/util/Background.dart';

class ExperimentalScreen extends StatelessWidget {
  const ExperimentalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // 🔥 black base
      body: Stack(
        children: [
          // 1. Background content
          const MyBackgroundContent(),

          // 2. Liquid glass layer
          LiquidGlassLayer(
            child: Stack(
              children: [
                // Example glass widget
                Center(
                  child: LiquidGlass(
                    shape: LiquidRoundedSuperellipse(borderRadius: 30),
                    child: const SizedBox.square(dimension: 100),
                  ),
                ),
              ],
            ),
          ),

          // 3. Normal UI (text on top)
          SafeArea(
            child: Center(
              child: Text(
                "Experimental Screen",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}