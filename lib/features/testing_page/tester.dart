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
            settings: const LiquidGlassSettings(
              thickness: 20,
              blur: 2,
              glassColor: Colors.black12,
            ),
            child: Stack(
              children: [
                Align(
                  alignment: const Alignment(.92, 0.72),
                  child: LiquidGlass(
                    shape: LiquidRoundedRectangle(borderRadius: 24),
                    child: const SizedBox(width: 48, height: 110),
                  ),
                ),


              //Searchbar Glass
                Align(
                  alignment: const Alignment(0, 0.95),
                  child: LiquidGlass(
                    shape: LiquidRoundedRectangle(
                      borderRadius: TSizes.searchbarGlassHeight / 2,
                    ),
                    child: const SizedBox(
                      width: 330,
                      height: TSizes.searchbarGlassHeight,
                    ),
                  ),
                ),


              //Search Bar with microphone icon
                Align(
                  alignment: const Alignment(-0.45, 0.925),
                  child: Container(
                    width: 250,
                    height: TSizes.searchbarHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        TSizes.searchbarHeight / 2,
                      ),
                      color: Colors.grey.withAlpha(20),
                    ),
                    child: const SizedBox(
                      width: 330,
                      height: TSizes.searchbarHeight,
                    ),
                  ),
                ),
                Align(
                  alignment: const Alignment(-0.45, 0.925),
                  child: Container(
                    width: 250,
                    height: TSizes.searchbarHeight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        TSizes.searchbarHeight / 2,
                      ),
                      color: Colors.grey.withAlpha(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(width: TSizes.spaceBtwItems),
                        GestureDetector(
                          onTap: () {
                            print("Search tapped");
                          },
                          child: Icon(
                            Icons.search,
                            color: Colors.white54,
                            size: TSizes.iconMd,
                          ),
                        ),
                        SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            print("Search tapped");
                          },
                          child: Text(
                            "Search Maps",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: TSizes.fontMd,
                            ),
                          ),
                        ),
                        SizedBox(
                          width:
                              TSizes.spaceBtwSections +
                              TSizes.spaceBtwItems +
                              20,
                        ),
                        GestureDetector(
                          onTap: () {
                            print("Microphone tapped");
                          },
                          child: Icon(
                            Icons.mic,
                            color: Colors.white54,
                            size: TSizes.iconMd,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),


              //Searchbar Avatar
                Align(
                  alignment: const Alignment(0.80, 0.935),
                  child: GestureDetector(
                    onTap: () {
                      print("Avatar pressed");
                    },
                    child: LiquidGlass(
                      shape: LiquidRoundedSuperellipse(
                        borderRadius: TSizes.searchbarAvatarHeight / 2,
                      ),
                      child: SizedBox(
                        width: TSizes.searchbarAvatarHeight,
                        height: TSizes.searchbarAvatarHeight,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            TSizes.searchbarAvatarHeight / 2,
                          ),
                          child: Image.network(
                            "https://i.pravatar.cc/150?img=3",
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
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
                            color: Colors.white.withAlpha(isPressed ? 25 : 0),
                            blurRadius: isPressed ? 12 : 15,
                            spreadRadius: isPressed ? 8 : 1,
                          ),
                        ],
                      ),
                      child: Container(
                        width: TSizes.iconLg,
                        height: TSizes.iconLg,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withAlpha(20),
                            width: 2,
                          ),
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
