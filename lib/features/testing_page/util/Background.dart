import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class MyBackgroundContent extends StatefulWidget {
  const MyBackgroundContent({super.key});

  @override
  State<MyBackgroundContent> createState() => _MyBackgroundContentState();
}

class _MyBackgroundContentState extends State<MyBackgroundContent> {
  final MapController _mapController = MapController();

  LatLng? currentLocation;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    // Check if location service is enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    // Request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    // Listen to real-time location
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      final latLng = LatLng(position.latitude, position.longitude);

      setState(() {
        currentLocation = latLng;
      });

      // Move camera to user
      _mapController.move(latLng, 16);
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: currentLocation ?? LatLng(22.5726, 88.3639),
        initialZoom: 13,
      ),
      children: [
        // 🌍 Map tiles
        TileLayer(
          urlTemplate:
              'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
          userAgentPackageName: 'com.example.helmet_app',
        ),

        // 📍 User location marker
        if (currentLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: currentLocation!,
                width: 30,
                height: 30,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withAlpha(120),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}