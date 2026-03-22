import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  LatLng? currentLocation;
  StreamSubscription<Position>? _positionStream;

  List<LatLng> routePoints = [];

  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

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

      // Keep camera centered on user
      _mapController.move(latLng, 16);
    });
  }

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LiquidGlassView(
        backgroundWidget: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(22.5726, 88.3639), // Kolkata
            initialZoom: 13,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
              userAgentPackageName: 'com.example.helmet_app',
            ),

            if (routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    strokeWidth: 5,
                    color: Colors.cyanAccent,
                  ),
                ],
              ),

            MarkerLayer(
              markers: [
                if (currentLocation != null)
                  Marker(
                    point: currentLocation!,
                    width: 40,
                    height: 40,
                    child: Container(
                      alignment: Alignment.center,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withAlpha(128),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Marker(
                    point: LatLng(22.5726, 88.3639),
                    width: 40,
                    height: 40,
                    child: Icon(Icons.location_pin, color: Colors.red, size: 40),
                  ),
                if (routePoints.isNotEmpty)
                  Marker(
                    point: routePoints.last,
                    width: 40,
                    height: 40,
                    child: Icon(Icons.flag, color: Colors.green, size: 40),
                  ),
              ],
            ),
          ],
        ),
        children: [
          LiquidGlass(
            width: 55,
            height: 55,
            position: LiquidGlassAlignPosition(
              alignment: Alignment(0,0.8),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 0),
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return Dialog(
                        backgroundColor: Colors.black,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: "Search destination...",
                              hintStyle: TextStyle(color: Colors.white54),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (value) {
                              Navigator.pop(context);
                              _searchLocation(value);
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
                child: Container(
                  height: 45,
                  width: 45,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(128),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: const Icon(Icons.search, color: Colors.white),
                ),
              ),
            ),
          ),

          

          LiquidGlass(
            width: 55,
            height: 55,
            position: LiquidGlassAlignPosition(
              alignment: Alignment.bottomRight,
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 100, right: 16),
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.white,
                onPressed: () {
                  if (currentLocation != null) {
                    _mapController.move(currentLocation!, 16);
                  }
                },
                child: Icon(Icons.my_location, color: Colors.black),
              ),
            ),
          ),
          
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _getRoute(LatLng(22.5800, 88.3800));
        },
        child: Icon(Icons.navigation),
      ),

      
    );
  }

  Future<void> _searchLocation(String query) async {
    final url =
        "https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1";

    final response = await http.get(Uri.parse(url), headers: {
      'User-Agent': 'helmet_app'
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data.isNotEmpty) {
        final lat = double.parse(data[0]['lat']);
        final lon = double.parse(data[0]['lon']);

        final destination = LatLng(lat, lon);

        // Call routing with new destination
        _getRoute(destination);
      }
    } else {
      debugPrint("Search error: ${response.body}");
    }
  }

  Future<void> _getRoute(LatLng destination) async {
    final start = currentLocation ?? LatLng(22.5726, 88.3639);

    final url =
        "https://graphhopper.com/api/1/route?point=${start.latitude},${start.longitude}&point=${destination.latitude},${destination.longitude}&vehicle=car&locale=en&points_encoded=true&key=3e31026e-a8af-42fd-9b15-00a9f9d92bb5";

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      final encoded = data['paths'][0]['points'];
      final decodedPoints = _decodePolyline(encoded);

      if (decodedPoints.isEmpty) return;

      setState(() {
        routePoints = decodedPoints;
      });

      _mapController.move(routePoints.first, 13);
    } else {
      debugPrint("GraphHopper error: ${response.body}");
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }
}