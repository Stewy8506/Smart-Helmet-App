import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import 'package:helmet_app/common/sizes.dart';
import 'package:helmet_app/features/grid_screen/grid_screen.dart';
import 'package:helmet_app/features/profile/profile.dart';
import 'package:helmet_app/features/voice_assistant/widgets/voice_fab.dart';
import 'package:helmet_app/features/hardware/mock_helmet_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  bool _isSwiping = false;

  final Set<Marker> _markers = {};

  final String _darkMapStyle = '''
  [
    {"elementType":"geometry","stylers":[{"color":"#212121"}]},
    {"elementType":"labels.text.fill","stylers":[{"color":"#a3a3a3"}]},
    {"elementType":"labels.text.stroke","stylers":[{"color":"#212121"}]},
    {"featureType":"road","elementType":"geometry","stylers":[{"color":"#2c2c2c"}]},
    {"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]}
  ]
  ''';

  GoogleMapController? _mapController;
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _initLocation();
    MockHelmetService.instance.start();
  }

  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    final pos = await Geolocator.getCurrentPosition();
    if (mounted && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 15),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
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
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: TSizes.spaceBtwSections),

                      // Title
                      Text(
                        "Your Nexus.",
                        textAlign: TextAlign.left,
                        style: GoogleFonts.bitcountPropSingle(
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                          fontSize: 38,
                        ),
                      ),

                      const SizedBox(height: TSizes.spaceBtwSections + 20),

                      // Helmet Image
                      ValueListenableBuilder<HelmetTelemetry>(
                        valueListenable: MockHelmetService.instance.telemetry,
                        builder: (context, telemetry, child) {
                          final battColor = telemetry.batteryPercent > 50 
                            ? Colors.greenAccent 
                            : telemetry.batteryPercent > 20 
                              ? Colors.orangeAccent 
                              : Colors.redAccent;
                          
                          return Column(
                            children: [
                              Center(
                                child: Align(
                                  alignment: const Alignment(0, 0),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Align(
                                        alignment: Alignment.center,
                                        child: SizedBox(
                                          width: 300,
                                          height: 300,
                                          child: CircularProgressIndicator(
                                            value: telemetry.batteryPercent / 100.0,
                                            strokeWidth: 12,
                                            backgroundColor: Colors.grey,
                                            valueColor: AlwaysStoppedAnimation(battColor.withAlpha(150)),
                                          ),
                                        ),
                                      ),
                                      Align(
                                        alignment: const Alignment(0.15, 0),
                                        child: Image.asset("assets/images/helmet.png", height: 220),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Center(
                                child: Text(
                                  "${telemetry.batteryPercent}% Battery",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      TweenAnimationBuilder<int>(
                        tween: IntTween(
                          begin: 0,
                          end:
                              "Tip: Maybe try unplugging your helmet once in a while? :)"
                                  .length,
                        ),
                        duration: const Duration(seconds: 2),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          final text =
                              "Tip: Maybe try unplugging your helmet once in a while? :)";
                          return Center(
                            child: Text(
                              text.substring(0, value),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w500,
                                color: Colors.white54,
                                fontSize: 9,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: TSizes.spaceBtwSections),

                      Align(
                        alignment: Alignment(-0.9, 0),
                        child: Text(
                          "Your Last Trip -",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),

                      const SizedBox(height: TSizes.spaceBtwItems + 5),

                      ValueListenableBuilder<HelmetTelemetry>(
                        valueListenable: MockHelmetService.instance.telemetry,
                        builder: (context, telemetry, child) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              const _StatItem(
                                icon: Icons.route,
                                label: "—",
                                sub: "Kilometers",
                              ),
                              _StatItem(
                                icon: Icons.favorite,
                                label: "${telemetry.heartRate}",
                                sub: "Avg. HR",
                              ),
                              _StatItem(
                                icon: Icons.local_fire_department,
                                label: "${telemetry.temperature}",
                                sub: "Avg. Temp.",
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // Route Preview (Google Maps)
                      SizedBox(
                        height: 300,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: IgnorePointer(
                            child: GoogleMap(
                              initialCameraPosition: const CameraPosition(
                                target: LatLng(26.22, 78.18),
                                zoom: 12,
                              ),
                              style: _darkMapStyle,
                              onMapCreated: (controller) {
                                _mapController = controller;
                                _initLocation();
                              },
                              polylines: _polylines,
                              markers: _markers,
                              zoomControlsEnabled: false,
                              myLocationEnabled: true,
                              myLocationButtonEnabled: false,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ), // Container

          Positioned(
            right: 20,
            bottom: 85,
            child: const VoiceFAB(),
          ),

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
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const GridScreen(),
                                ),
                              );
                            }
                          });
                        } else if (details.delta.dx < -5 &&
                            _selectedIndex > 0) {
                          _isSwiping = true;
                          HapticFeedback.lightImpact();
                          setState(() {
                            _selectedIndex--;
                            if (_selectedIndex == 1) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const GridScreen(),
                                ),
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
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: AnimatedScale(
                                      scale: _selectedIndex == 0 ? 1.2 : 0.8,
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
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
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const GridScreen(),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: AnimatedScale(
                                      scale: _selectedIndex == 1 ? 1.2 : 0.8,
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
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
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const ProfileScreen(),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: AnimatedScale(
                                      scale: _selectedIndex == 2 ? 1.2 : 0.8,
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
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

          const SizedBox(height: TSizes.spaceBtwSections),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;

  const _StatItem({required this.icon, required this.label, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}
