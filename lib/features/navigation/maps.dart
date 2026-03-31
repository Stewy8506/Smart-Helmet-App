import 'package:flutter/material.dart';

import 'package:helmet_app/common/sizes.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';


import 'package:helmet_app/features/testing_page/util/background.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  bool isPressed = false;
  bool isSearching = false;
  final FocusNode _searchFocus = FocusNode();
  Position? _currentPosition;
  CameraPosition? _lastCameraPosition;

  List<dynamic> _suggestions = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() {
      setState(() {
        isSearching = _searchFocus.hasFocus;
      });
    });
    Geolocator.getLastKnownPosition().then((pos) {
      if (pos != null) {
        _currentPosition = pos;
      }
    });
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _searchLocation(String query) async {
    final apiKey =
        "AIzaSyDAEEbOqNnJ_Bip7X86ao-ZUDQayCE4aRI"; // replace if needed

    final url = Uri.parse(
      "https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=$query&inputtype=textquery&fields=geometry&key=$apiKey",
    );

    try {
      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['candidates'] != null && data['candidates'].isNotEmpty) {
        final location = data['candidates'][0]['geometry']['location'];
        final lat = location['lat'];
        final lon = location['lng'];

        globalMapController?.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(lat, lon), 16),
        );
      }
    } catch (e) {
      print("Places search error: $e");
    }
  }

  Future<void> _fetchSuggestions(String input) async {
    if (input.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }

    final apiKey = "AIzaSyDAEEbOqNnJ_Bip7X86ao-ZUDQayCE4aRI";

    String baseUrl =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$apiKey";

    if (_currentPosition != null) {
      final lat = _currentPosition!.latitude;
      final lng = _currentPosition!.longitude;
      baseUrl += "&location=$lat,$lng&radius=5000&components=country:in";
    }

    final url = Uri.parse(baseUrl);

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          setState(() {
            _suggestions = data['predictions'];
          });
        } else {
          setState(() => _suggestions = []);
          print("Autocomplete API status: ${data['status']}");
        }
      } else {
        print("HTTP error: ${response.statusCode}");
      }
    } catch (e) {
      print("Autocomplete error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const MyBackgroundContent(),
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                FocusScope.of(context).unfocus();
              },
            ),
          ),

          LiquidGlassLayer(
            settings: const LiquidGlassSettings(
              thickness: 20,
              blur: 2,
              glassColor: Colors.black26,
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
                                globalMapController?.animateCamera(
                                  CameraUpdate.zoomIn(),
                                );
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
                                globalMapController?.animateCamera(
                                  CameraUpdate.zoomOut(),
                                );
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
                        Position position =
                            await Geolocator.getCurrentPosition();
                        final latLng = LatLng(
                          position.latitude,
                          position.longitude,
                        );
                        globalMapController?.animateCamera(
                          CameraUpdate.newLatLngZoom(latLng, 16),
                        );
                      } catch (e) {
                        print("Location error: $e");
                      }
                    },
                    child: const Icon(Icons.my_location, color: Colors.white70),
                  ),
                ),

                // Map Rotation Toggle Button
                Align(
                  alignment: const Alignment(.92, 0.26),
                  child: _AnimatedButton(
                    borderRadius: 24,
                    onTap: () async {
                      final cameraPosition = _lastCameraPosition;

                      if (cameraPosition != null) {
                        globalMapController?.animateCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(
                              target: cameraPosition.target,
                              zoom: cameraPosition.zoom,
                              tilt: 45,
                              bearing: cameraPosition.bearing + 45,
                            ),
                          ),
                        );
                      }
                    },
                    child: const Icon(Icons.explore, color: Colors.white70),
                  ),
                ),

                //Back Button (combined)
                Align(
                  alignment: const Alignment(-0.95, -0.89),
                  child: _AnimatedButton(
                    borderRadius: TSizes.backbuttonSize / 2,
                    onTap: () {
                      Navigator.pushNamed(context, '/grid_screen');
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

                //Searchbar Glass (expanding)
                Align(
                  alignment: const Alignment(0, 0.95),
                  child: GestureDetector(
                    onTap: () {}, // absorb taps so it doesn't collapse
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      width: 355,
                      height: isSearching
                          ? TSizes.searchbarGlassHeight + 250
                          : TSizes.searchbarGlassHeight,
                      child: LiquidGlass(
                        shape: LiquidRoundedRectangle(
                          borderRadius: TSizes.searchbarGlassHeight / 2,
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                              height: TSizes.searchbarGlassHeight,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Stack(
                                        children: [
                                          ...[
                                            Positioned(
                                              left: 2,
                                              right: 6,
                                              top: 0,
                                              bottom: 0,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(
                                                    TSizes.searchbarHeight / 2,
                                                  ),
                                                  color: Colors.grey.withAlpha(20),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              left: 12,
                                              top: 0,
                                              bottom: 0,
                                              child: Center(
                                                child: GestureDetector(
                                                  onTap: () {
                                                    FocusScope.of(context).requestFocus(_searchFocus);
                                                  },
                                                  child: const Icon(
                                                    Icons.search,
                                                    color: Colors.white54,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              right: 20,
                                              top: 0,
                                              bottom: 0,
                                              child: Center(
                                                child: GestureDetector(
                                                  onTap: () {
                                                    print("Microphone tapped");
                                                  },
                                                  child: Icon(
                                                    Icons.mic,
                                                    color: Colors.white54,
                                                    size: TSizes.iconMd,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(left: 50, right: 40),
                                              child: TextField(
                                                controller: _searchController,
                                                focusNode: _searchFocus,
                                                style: const TextStyle(color: Colors.white),
                                                decoration: const InputDecoration(
                                                  hintText: "Search Maps",
                                                  hintStyle: TextStyle(color: Colors.white54),
                                                  border: InputBorder.none,
                                                ),
                                                onChanged: (value) {
                                                  Future.delayed(const Duration(milliseconds: 300), () {
                                                    if (value == _searchController.text) {
                                                      _fetchSuggestions(value);
                                                    }
                                                  });
                                                },
                                                onSubmitted: (value) {
                                                  if (value.isNotEmpty) {
                                                    _searchLocation(value);
                                                    setState(() => _suggestions = []);
                                                  }
                                                  FocusScope.of(context).unfocus();
                                                },
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(right: 2),
                                      child: Align(
                                        alignment: const Alignment(0, 0),
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
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isSearching) ...[
                              if (_suggestions.isNotEmpty)
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {},
                                    child: ListView.builder(
                                      itemCount: _suggestions.length,
                                      itemBuilder: (context, index) {
                                        final item = _suggestions[index];
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          child: GestureDetector(
                                            onTap: () {
                                              final description =
                                                  item['description'];
                                              _searchController.text =
                                                  description;

                                              setState(() {
                                                _suggestions = [];
                                              });

                                              _searchLocation(description);
                                              FocusScope.of(context).unfocus();
                                            },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 14,
                                                    vertical: 14,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withAlpha(
                                                  15,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: Colors.white.withAlpha(
                                                    20,
                                                  ),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.place,
                                                    color: Colors.white54,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Text(
                                                      item['description'],
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 14,
                                                      ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Container(
                                                    width: 36,
                                                    height: 36,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withAlpha(20),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                    child: const Icon(
                                                      Icons.location_on,
                                                      color: Colors.white70,
                                                      size: 18,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              if (_suggestions.isEmpty) ...[
                                const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "Places",
                                      style: GoogleFonts.montserrat(
                                        color: Colors.white70,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _quickCircle(Icons.home, "Home"),
                                    _quickCircle(Icons.work, "Work"),
                                    _quickCircle(Icons.add, "Add"),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "Your Guides",
                                      style: GoogleFonts.montserrat(
                                        color: Colors.white70,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
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

// Reusable animated button for LiquidGlass-based controls
class _AnimatedButton extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final VoidCallback onTap;
  final double? width;
  final double? height;
  const _AnimatedButton({
    required this.child,
    required this.borderRadius,
    required this.onTap,
    this.width,
    this.height,
  });

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
            ? (Matrix4.identity()..scaleByDouble(0.95, 0.95, 1.0, 1.0))
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
  const _AnimatedAvatarButton({
    required this.child,
    required this.borderRadius,
    required this.onTap,
  });

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
            ? (Matrix4.identity()..scaleByDouble(0.95, 0.95, 1.0, 1.0))
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
            width: 48,
            height: 48,
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
    required this.icon,
    required this.onTap,
    required this.isTop,
  });
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
            ? (Matrix4.identity()..scaleByDouble(0.95, 0.95, 1.0, 1.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: widget.isTop ? const Radius.circular(24) : Radius.zero,
            topRight: widget.isTop ? const Radius.circular(24) : Radius.zero,
            bottomLeft: !widget.isTop ? const Radius.circular(24) : Radius.zero,
            bottomRight: !widget.isTop
                ? const Radius.circular(24)
                : Radius.zero,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withAlpha(isPressed ? 25 : 0),
              blurRadius: isPressed ? 12 : 15,
              spreadRadius: isPressed ? 8 : 1,
            ),
          ],
        ),
        child: Center(child: Icon(widget.icon, color: Colors.white70)),
      ),
    );
  }
}

Widget _quickCircle(IconData icon, String label) {
  return Column(
    children: [
      Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.blue.withAlpha(77), // 0.3 * 255
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white),
      ),
      const SizedBox(height: 6),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    ],
  );
}
