import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:helmet_app/common/sizes.dart';
import 'package:helmet_app/common/text.dart';

import 'package:helmet_app/features/testing_page/util/background.dart';

class ExperimentalScreen extends StatefulWidget {
  const ExperimentalScreen({super.key});

  @override
  State<ExperimentalScreen> createState() => _ExperimentalScreenState();
}

class _ExperimentalScreenState extends State<ExperimentalScreen> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const MyBackgroundContent(),

          LiquidGlassLayer(
            settings: const LiquidGlassSettings(thickness: 20, blur: 1.2),
            child: Stack(
              children: [
                Align(
                  alignment: const Alignment(0, 0),
                  child: LiquidGlass(
                    shape: LiquidRoundedRectangle(borderRadius: 20),
                    child: const SizedBox(width: 50, height: 110),
                  ),
                ),

                Align(
                  alignment: const Alignment(0, 0),
                  child: GestureDetector(
                    onTapDown: (_) {
                      setState(() => isPressed = true);
                    },
                    onTapUp: (_) {
                      setState(() => isPressed = false);
                    },
                    onTapCancel: () {
                      setState(() => isPressed = false);
                    },
                    onTap: () {
                      print("Tapped");
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      transformAlignment: Alignment.center,
                      transform: isPressed
                          ? (Matrix4.identity()
                              ..scaleByDouble(0.95, 0.95, 1.0, 1.0))
                          : Matrix4.identity(),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        //borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withAlpha(isPressed ? 5 : 0),
                            blurRadius: isPressed ? 12 : 15,
                            spreadRadius: isPressed ? 8 : 1,
                          ),
                        ],
                      ),
                      child: Container(
																							width: 50,
																							height: 50,
																							decoration: BoxDecoration(
																								shape: BoxShape.circle,
																								border: Border.all(
																									color: Colors.white.withAlpha(20),
																									width: 2
																								)
																							),
                        //shape: LiquidRoundedSuperellipse(borderRadius: 50),
                        //child: const SizedBox(width: 50, height: 50),
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
