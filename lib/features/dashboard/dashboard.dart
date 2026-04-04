import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:ui' as ui;

import 'package:helmet_app/common/sizes.dart';
import 'package:helmet_app/features/grid_screen/grid_screen.dart';
import 'package:helmet_app/features/profile/profile.dart';

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

  Future<BitmapDescriptor> _createBlueDotMarker() async {
    const int size = 20;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    final Paint paint = Paint()..color = const Color(0xFF2196F3);

    // Draw circle
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2.5, paint);

    // Optional white border for visibility
    final Paint border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2.5, border);

    final img = await recorder.endRecording().toImage(size, size);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(data!.buffer.asUint8List());
  }

  Future<void> _loadRoute() async {
    PolylinePoints polylinePoints = PolylinePoints(
      apiKey: dotenv.env['GOOGLE_MAPS_API_KEY']!,
    );

    RoutesApiResponse response = await polylinePoints
        .getRouteBetweenCoordinatesV2(
          request: RoutesApiRequest(
            origin: PointLatLng(26.1918531, 78.1906922),
            destination: PointLatLng(26.249564, 78.174351),
            travelMode: TravelMode.driving,
          ),
        );

    if (response.routes.isNotEmpty) {
      final points = response.routes.first.polylinePoints ?? [];

      List<LatLng> routePoints = points
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();

      setState(() {
        _polylines.clear();
        _markers.clear();

        _polylines.add(
          Polyline(
            polylineId: const PolylineId("real_route"),
            color: Colors.blueAccent,
            width: 5,
            points: routePoints,
          ),
        );

        if (routePoints.isNotEmpty) {
          // Add blue dot marker for start
          // Since this is an async call, we must await the marker creation
          // But since we're in setState, we need to do this outside setState. So move this block outside setState.
        }
      });

      // Add blue dot marker for start (await outside setState)
      if (routePoints.isNotEmpty) {
        final blueDot = await _createBlueDotMarker();

        setState(() {
          _markers.add(
            Marker(
              markerId: const MarkerId("start"),
              position: routePoints.first,
              icon: blueDot,
              anchor: const Offset(0.5, 0.5),
            ),
          );
          _markers.add(
            Marker(
              markerId: const MarkerId("end"),
              position: routePoints.last,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
            ),
          );
        });
      }

      // Fit bounds
      if (_mapController != null && routePoints.isNotEmpty) {
        double minLat = routePoints.first.latitude;
        double maxLat = routePoints.first.latitude;
        double minLng = routePoints.first.longitude;
        double maxLng = routePoints.first.longitude;

        for (var point in routePoints) {
          if (point.latitude < minLat) minLat = point.latitude;
          if (point.latitude > maxLat) maxLat = point.latitude;
          if (point.longitude < minLng) minLng = point.longitude;
          if (point.longitude > maxLng) maxLng = point.longitude;
        }

        LatLngBounds bounds = LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        );

        _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
      }
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
                      Center(
                        child: Align(
                          alignment: const Alignment(
                            0,
                            0,
                          ), // adjust to move whole component
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Align(
                                alignment: Alignment.center,
                                child: SizedBox(
                                  width: 300,
                                  height: 300,
                                  child: CircularProgressIndicator(
                                    value: 1,
                                    strokeWidth: 12,
                                    backgroundColor: Colors.grey,
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.greenAccent.withAlpha(150),
                                    ),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: const Alignment(
                                  0.15,
                                  0,
                                ), // tweak to adjust helmet inside the ring
                                child: Image.asset(
                                  "assets/images/helmet.png",
                                  height: 220,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Center(
                        child: Text(
                          "~ ∞ hours",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
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

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: const [
                          _StatItem(
                            icon: Icons.route,
                            label: "11.5",
                            sub: "Kilometers",
                          ),
                          _StatItem(
                            icon: Icons.favorite,
                            label: "97.4",
                            sub: "Avg. HR",
                          ),
                          _StatItem(
                            icon: Icons.local_fire_department,
                            label: "37",
                            sub: "Avg. Temp.",
                          ),
                        ],
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
                                _loadRoute();
                              },
                              polylines: _polylines,
                              markers: _markers,
                              zoomControlsEnabled: false,
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
