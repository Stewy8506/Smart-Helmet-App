import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:helmet_app/common/sizes.dart';
import 'package:helmet_app/common/text.dart';

import 'package:helmet_app/features/testing_page/util/Background.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

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

                //Zoom Controls
                Align(
                  alignment: const Alignment(.92, 0.72),
                  child: LiquidGlass(
                    shape: LiquidRoundedRectangle(borderRadius: 24),
                    child: SizedBox(
                      width: 48,
                      height: 110,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _ZoomButton(
                              icon: Icons.add,
                              isTop: true,
                              onTap: () {
                                double currentZoom = globalMapController.camera.zoom;
                                double targetZoom = (currentZoom + 1).clamp(3.0, 18.0);
                                for (int i = 0; i <= 10; i++) {
                                  double t = i / 10;
                                  double eased = Curves.easeInOut.transform(t);
                                  double z = currentZoom + (targetZoom - currentZoom) * eased;
                                  Future.delayed(Duration(milliseconds: i * 16), () {
                                    globalMapController.move(
                                      globalMapController.camera.center,
                                      z,
                                    );
                                  });
                                }
                              },
                            ),
                          ),
                          Container(
                            width: 20,
                            height: 1,
                            color: Colors.white24,
                          ),
                          Expanded(
                            child: _ZoomButton(
                              icon: Icons.remove,
                              isTop: false,
                              onTap: () {
                                double currentZoom = globalMapController.camera.zoom;
                                double targetZoom = (currentZoom - 1).clamp(3.0, 18.0);
                                for (int i = 0; i <= 10; i++) {
                                  double t = i / 10;
                                  double eased = Curves.easeInOut.transform(t);
                                  double z = currentZoom + (targetZoom - currentZoom) * eased;
                                  Future.delayed(Duration(milliseconds: i * 16), () {
                                    globalMapController.move(
                                      globalMapController.camera.center,
                                      z,
                                    );
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                //Locate Me Button
                Align(
                  alignment: const Alignment(.92, 0.42),
                  child: _AnimatedButton(
                    borderRadius: 24,
                    onTap: () async {
                      try {
                        Position position = await Geolocator.getCurrentPosition();
                        LatLng latLng = LatLng(position.latitude, position.longitude);
                        globalMapController.move(latLng, 16);
                      } catch (e) {
                        print("Location error: $e");
                      }
                    },
                    child: const Icon(
                      Icons.my_location,
                      color: Colors.white70,
                    ),
                  ),
                ),

                // Map Rotation Toggle Button
                Align(
                  alignment: const Alignment(.92, 0.26),
                  child: _AnimatedButton(
                    borderRadius: 24,
                    onTap: () {
                      double currentRotation = globalMapController.camera.rotation;
                      double targetRotation = currentRotation.abs() < 1 ? 45 : 0;
                      for (int i = 0; i <= 10; i++) {
                        double t = i / 10;
                        double eased = Curves.easeInOut.transform(t);
                        double rot = currentRotation + (targetRotation - currentRotation) * eased;
                        Future.delayed(Duration(milliseconds: i * 20), () {
                          globalMapController.rotate(rot);
                        });
                      }
                    },
                    child: Builder(
                      builder: (context) {
                        double rotation = globalMapController.camera.rotation;
                        return Transform.rotate(
                          angle: -rotation * (3.14159 / 180),
                          child: const Icon(
                            Icons.explore,
                            color: Colors.white70,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                //Back Button (combined)
                Align(
                  alignment: const Alignment(-0.95, -0.89),
                  child: _AnimatedButton(
                    borderRadius: TSizes.backbuttonSize / 2,
                    onTap: () {
                      print("Back button tapped");
                    },
                    width: TSizes.backbuttonSize,
                    height: TSizes.backbuttonSize,
                    child: Image.network(
                      "https://img.icons8.com/ios-filled/100/ffffff/back.png",
                      width: TSizes.iconMd,
                      height: TSizes.iconMd,
                      color: Colors.white54,
                    ),
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
                            style: GoogleFonts.montserrat(
                              color: Colors.white54,
                              fontSize: TSizes.fontMd,
                            ),
                          ),
                        ),
                        SizedBox(
                          width:
                              TSizes.spaceBtwSections +
                              TSizes.spaceBtwItems +
                              12,
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
                  child: _AnimatedButton(
                    borderRadius: TSizes.searchbarAvatarHeight / 2,
                    onTap: () {
                      print("Avatar pressed");
                    },
                    width: TSizes.searchbarAvatarHeight,
                    height: TSizes.searchbarAvatarHeight,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        TSizes.searchbarAvatarHeight / 2,
                      ),
                      child: Image.asset(
                        "assets/images/avatar.jpg",
                        fit: BoxFit.cover,
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
                            color: Colors.white.withAlpha(isPressed ? 20 : 0),
                            blurRadius: isPressed ? 4 : 15,
                            spreadRadius: isPressed ? 4 : 1,
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

// Reusable animated button for LiquidGlass-based controls
class _AnimatedButton extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final VoidCallback onTap;
  final double? width;
  final double? height;
  const _AnimatedButton({
    Key? key,
    required this.child,
    required this.borderRadius,
    required this.onTap,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton> {
  bool isPressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => isPressed = true),
      onTapUp: (_) => setState(() => isPressed = false),
      onTapCancel: () => setState(() => isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transformAlignment: Alignment.center,
        transform: isPressed
            ? (Matrix4.identity()..scale(0.95, 0.95, 1.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withAlpha(isPressed ? 20 : 0),
              blurRadius: isPressed ? 4 : 15,
              spreadRadius: isPressed ? 4 : 1,
            ),
          ],
        ),
        child: LiquidGlass(
          shape: LiquidRoundedRectangle(borderRadius: widget.borderRadius),
          child: SizedBox(
            width: widget.width ?? 48,
            height: widget.height ?? 48,
            child: Center(child: widget.child),
          ),
        ),
      ),
    );
  }
}

// Special avatar version with superellipse
class _AnimatedAvatarButton extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final VoidCallback onTap;
  final double? width;
  final double? height;
  const _AnimatedAvatarButton({
    Key? key,
    required this.child,
    required this.borderRadius,
    required this.onTap,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  State<_AnimatedAvatarButton> createState() => _AnimatedAvatarButtonState();
}

class _AnimatedAvatarButtonState extends State<_AnimatedAvatarButton> {
  bool isPressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => isPressed = true),
      onTapUp: (_) => setState(() => isPressed = false),
      onTapCancel: () => setState(() => isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transformAlignment: Alignment.center,
        transform: isPressed
            ? (Matrix4.identity()..scale(0.95, 0.95, 1.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.white.withAlpha(isPressed ? 25 : 0),
              blurRadius: isPressed ? 12 : 15,
              spreadRadius: isPressed ? 8 : 1,
            ),
          ],
        ),
        child: LiquidGlass(
          shape: LiquidRoundedSuperellipse(borderRadius: widget.borderRadius),
          child: SizedBox(
            width: widget.width ?? 48,
            height: widget.height ?? 48,
            child: Center(child: widget.child),
          ),
        ),
      ),
    );
  }
}

// For zoom + and - buttons (icon only)
class _ZoomButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isTop;
  const _ZoomButton({
    Key? key,
    required this.icon,
    required this.onTap,
    required this.isTop,
  }) : super(key: key);
  @override
  State<_ZoomButton> createState() => _ZoomButtonState();
}

class _ZoomButtonState extends State<_ZoomButton> {
  bool isPressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => isPressed = true),
      onTapUp: (_) => setState(() => isPressed = false),
      onTapCancel: () => setState(() => isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transformAlignment: Alignment.center,
        transform: isPressed
            ? (Matrix4.identity()..scale(0.95, 0.95, 1.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: widget.isTop ? const Radius.circular(24) : Radius.zero,
            topRight: widget.isTop ? const Radius.circular(24) : Radius.zero,
            bottomLeft: !widget.isTop ? const Radius.circular(24) : Radius.zero,
            bottomRight: !widget.isTop ? const Radius.circular(24) : Radius.zero,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withAlpha(isPressed ? 25 : 0),
              blurRadius: isPressed ? 12 : 15,
              spreadRadius: isPressed ? 8 : 1,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            widget.icon,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }
}