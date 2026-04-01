import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';

import 'package:helmet_app/common/sizes.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import 'package:helmet_app/features/navigation/util/background.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'dart:math' as math;
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
  double _lastBearing = 0;

  List<dynamic> _suggestions = [];
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();

  StreamSubscription<Position>? _positionStream;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  List<LatLng> _routePoints = [];
  List<dynamic> _steps = [];
  int _currentStepIndex = 0;
  String _currentInstruction = "Start navigation";
  // Navigation UI state and ETA fields
  bool _isNavigating = false;
  bool _isPreviewingRoute = false;
  String _etaText = "";
  String _distanceText = "";
  String _arrivalText = "";
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() {
      final newState = _searchFocus.hasFocus;
      if (newState != isSearching && mounted) {
        setState(() {
          isSearching = newState;
        });
      }
    });
    Geolocator.getLastKnownPosition().then((pos) {
      if (pos != null) {
        _currentPosition = pos;

        final latLng = LatLng(pos.latitude, pos.longitude);

        // Move camera once map is ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (globalMapController != null) {
            globalMapController!.moveCamera(
              CameraUpdate.newLatLngZoom(latLng, 16),
            );
          }
        });
      }
    });
    _tts.setSpeechRate(0.5);
    _tts.setVolume(1.0);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchFocus.dispose();
    _positionStream?.cancel();
    _tts.stop();
    super.dispose();
  }

  Future<void> _searchLocation(String query) async {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];

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

  Future<void> _getRouteWithSteps(LatLng destination) async {
    if (_currentPosition == null) return;

    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    final origin =
        "${_currentPosition!.latitude},${_currentPosition!.longitude}";
    final dest = "${destination.latitude},${destination.longitude}";

    final url = Uri.parse(
      "https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$dest&mode=driving&key=$apiKey",
    );

    final res = await http.get(url);
    final data = json.decode(res.body);

    if (data['routes'].isNotEmpty) {
      final route = data['routes'][0];
      final encoded = route['overview_polyline']['points'];
      final legs = route['legs'][0]['steps'];

      // ETA/distance/arrival computation
      final leg = route['legs'][0];
      final duration = leg['duration']['text'];
      final distance = leg['distance']['text'];
      final arrival = DateTime.now().add(
        Duration(seconds: leg['duration']['value']),
      );
      final formattedArrival =
          "${arrival.hour % 12 == 0 ? 12 : arrival.hour % 12}:${arrival.minute.toString().padLeft(2, '0')} ${arrival.hour >= 12 ? 'PM' : 'AM'}";

      _decodePolyline(encoded);
      // Zoom out to show full route preview
      if (_routePoints.isNotEmpty) {
        globalMapController?.animateCamera(
          CameraUpdate.newLatLngBounds(_getBounds(_routePoints), 80),
        );
      }
      final marker = Marker(
        markerId: const MarkerId("destination"),
        position: destination,
      );

      setState(() {
        _steps = legs;
        _currentStepIndex = 0;
        _currentInstruction = _cleanHtml(legs[0]['html_instructions']);
        _isPreviewingRoute = true;
        _etaText = duration;
        _distanceText = distance;
        _arrivalText = formattedArrival;
        _markers = {marker};
      });
      // No _startNavigation() here
    }
  }

  void _startActualNavigation() {
    setState(() {
      _isPreviewingRoute = false;
      _isNavigating = true;
    });

    if (_currentPosition != null) {
      final userLatLng = LatLng(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      globalMapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: userLatLng,
            zoom: 18,
            tilt: 60,
            bearing: _lastBearing,
          ),
        ),
      );
    }

    _startNavigation();
  }

  IconData _getDirectionIcon(String instruction) {
    final text = instruction.toLowerCase();

    if (text.contains("left")) return Icons.turn_left;
    if (text.contains("right")) return Icons.turn_right;
    if (text.contains("straight")) return Icons.straight;
    if (text.contains("u-turn")) return Icons.u_turn_left;
    if (text.contains("roundabout")) return Icons.roundabout_left;

    return Icons.navigation;
  }

  String _cleanHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  void _startNavigation() {
    _positionStream?.cancel();

    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 2,
          ),
        ).listen((pos) {
          final userLatLng = LatLng(pos.latitude, pos.longitude);

          final rawBearing = pos.heading;
          final bearing = rawBearing > 0
              ? (_lastBearing * 0.7 + rawBearing * 0.3)
              : _lastBearing;

          _lastBearing = bearing;

          final offsetTarget = _offsetLatLng(userLatLng, bearing);

          double speed = pos.speed;

          double zoom = speed > 10 ? 17 : 18;
          double tilt = speed > 10 ? 50 : 60;

          globalMapController?.moveCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: offsetTarget,
                zoom: zoom,
                tilt: tilt,
                bearing: bearing,
              ),
            ),
          );

          _updateStep(userLatLng);
        });
  }

  LatLng _offsetLatLng(LatLng position, double heading) {
    const double distance = 0.0003;

    final rad = heading * (math.pi / 180);

    final newLat = position.latitude + distance * math.cos(rad);
    final newLng = position.longitude + distance * math.sin(rad);

    return LatLng(newLat, newLng);
  }

  void _updateStep(LatLng current) async {
    if (_steps.isEmpty) return;

    final step = _steps[_currentStepIndex];
    final end = step['end_location'];

    final distance = Geolocator.distanceBetween(
      current.latitude,
      current.longitude,
      end['lat'],
      end['lng'],
    );

    if (distance < 20) {
      if (_currentStepIndex < _steps.length - 1) {
        _currentStepIndex++;
        final next = _steps[_currentStepIndex];
        final instruction = _cleanHtml(next['html_instructions']);

        setState(() {
          _currentInstruction = instruction;
        });

        _tts.speak(instruction);
      }
    }

    if (_routePoints.isNotEmpty) {
      final routeDistance = Geolocator.distanceBetween(
        current.latitude,
        current.longitude,
        _routePoints.first.latitude,
        _routePoints.first.longitude,
      );

      if (routeDistance > 50) {
        await _getRouteWithSteps(_routePoints.last);
      }
    }
  }

  void _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }

    print("ROUTE POINTS: ${polyline.length}");
    setState(() {
      _routePoints = polyline;
      _polylines = {
        Polyline(
          polylineId: const PolylineId("route"),
          points: polyline,
          width: 6,
          color: Colors.blueAccent,
        ),
      };
    });
  }

  LatLngBounds _getBounds(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Future<void> _fetchSuggestions(String input) async {
    if (input.isEmpty) {
      if (_suggestions.isNotEmpty && mounted) {
        setState(() => _suggestions = []);
      }
      return;
    }

    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];

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
          final newList = data['predictions'];

          if (!mounted) return;

          if (_suggestions.length == newList.length &&
              _suggestions.isNotEmpty &&
              newList.isNotEmpty &&
              _suggestions[0]['description'] == newList[0]['description']) {
            return; // prevent useless rebuild
          }

          setState(() {
            _suggestions = newList;
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

  double _calculateSearchHeight() {
    const double itemHeight = 70;
    const double maxHeight = 500;

    double calculated =
        TSizes.searchbarGlassHeight + (_suggestions.length * itemHeight);

    if (calculated > maxHeight) return maxHeight;
    return calculated;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map background with polylines overlay
          MyBackgroundContent(polylines: _polylines, markers: _markers),
          const Positioned.fill(child: _DismissKeyboardLayer()),

          LiquidGlassLayer(
            settings: const LiquidGlassSettings(
              thickness: 20,
              blur: 2,
              glassColor: Colors.black26,
            ),
            child: Stack(
              children: [
                // Navigation Overlay (only during navigation)
                if (_isNavigating)
                  Align(
                    alignment: const Alignment(0, -0.85),
                    child: LiquidGlass(
                      shape: LiquidRoundedRectangle(borderRadius: 20),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        width: 320,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "Navigation",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(
                                  _getDirectionIcon(_currentInstruction),
                                  color: Colors.white,
                                  size: 28,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _currentInstruction,
                                    style: const TextStyle(
                                      color: Colors.white70,
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
                //Zoom Controls
                if (!_isNavigating && !isSearching)
                  Align(
                    alignment: Alignment(
                      .92,
                      (_isPreviewingRoute || _isNavigating) ? 0.65 : 0.72,
                    ),
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
                if (!_isNavigating && !isSearching)
                  Align(
                    alignment: Alignment(
                      .92,
                      (_isPreviewingRoute || _isNavigating) ? 0.36 : 0.42,
                    ),
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
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.white70,
                      ),
                    ),
                  ),

                // Map Rotation Toggle Button
                if (!_isNavigating && !isSearching)
                  Align(
                    alignment: Alignment(
                      .92,
                      (_isPreviewingRoute || _isNavigating) ? 0.2 : 0.26,
                    ),
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
                if (!_isNavigating)
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

                // Animated search/navigation bar (Google Maps style)
                AnimatedAlign(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  alignment: const Alignment(0, 0.95),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    width: 355,
                    height: (_isNavigating || _isPreviewingRoute)
                        ? 90
                        : (isSearching
                              ? _calculateSearchHeight() + 14
                              : TSizes.searchbarGlassHeight),
                    child: LiquidGlass(
                      shape: LiquidRoundedRectangle(
                        borderRadius: TSizes.searchbarGlassHeight / 2,
                      ),
                      child: (_isNavigating || _isPreviewingRoute)
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isNavigating = false;
                                        _isPreviewingRoute = false;
                                        _polylines = {};
                                        _searchController.clear();
                                        _suggestions = [];
                                        _markers = {};
                                      });
                                      _positionStream?.cancel();
                                    },
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _etaText,
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "$_distanceText • $_arrivalText",
                                          style: const TextStyle(
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_isPreviewingRoute)
                                    GestureDetector(
                                      onTap: _startActualNavigation,
                                      child: const Icon(
                                        Icons.navigation,
                                        color: Colors.blueAccent,
                                      ),
                                    ),
                                ],
                              ),
                            )
                          : Column(
                              children: [
                                if (isSearching)
                                  GestureDetector(
                                    onVerticalDragUpdate: (details) {
                                      if (details.primaryDelta != null &&
                                          details.primaryDelta! > 6) {
                                        FocusScope.of(context).unfocus();
                                        setState(() {
                                          _suggestions = [];
                                          isSearching = false;
                                        });
                                      }
                                    },
                                    child: Center(
                                      child: AnimatedOpacity(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        opacity: isSearching ? 1 : 0,
                                        child: Container(
                                          margin: const EdgeInsets.only(
                                            top: 6,
                                            bottom: 2,
                                          ),
                                          width: 40,
                                          height: 5,
                                          decoration: BoxDecoration(
                                            color: Colors.white38,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
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
                                              Positioned(
                                                left: 2,
                                                right: 53,
                                                top: 0,
                                                bottom: 0,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          TSizes.searchbarHeight /
                                                              2,
                                                        ),
                                                    color: Colors.grey
                                                        .withAlpha(20),
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
                                                      FocusScope.of(
                                                        context,
                                                      ).requestFocus(
                                                        _searchFocus,
                                                      );
                                                    },
                                                    child: const Icon(
                                                      Icons.search,
                                                      color: Colors.white54,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                right: 2,
                                                top: 0,
                                                bottom: 0,
                                                child: Center(
                                                  child: _AnimatedAvatarButton(
                                                    borderRadius: 24,
                                                    onTap: () {
                                                      // You can navigate to profile or settings later
                                                      print("Avatar tapped");
                                                    },
                                                    child: const Icon(
                                                      Icons.person,
                                                      color: Colors.white70,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  left: 50,
                                                  right: 50,
                                                ),
                                                child: TextField(
                                                  controller: _searchController,
                                                  focusNode: _searchFocus,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                  decoration:
                                                      const InputDecoration(
                                                        hintText:
                                                            "Search Maps    ",
                                                        hintStyle: TextStyle(
                                                          color: Colors.white54,
                                                        ),
                                                        border:
                                                            InputBorder.none,
                                                      ),
                                                  onChanged: (value) {
                                                    _debounce?.cancel();
                                                    _debounce = Timer(
                                                      const Duration(
                                                        milliseconds: 300,
                                                      ),
                                                      () {
                                                        _fetchSuggestions(
                                                          value,
                                                        );
                                                      },
                                                    );
                                                  },
                                                  onSubmitted: (value) async {
                                                    FocusScope.of(
                                                      context,
                                                    ).unfocus();
                                                    if (value.isNotEmpty) {
                                                      await _searchLocation(
                                                        value,
                                                      );
                                                      setState(
                                                        () => _suggestions = [],
                                                      );
                                                    }
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // --- Autocomplete Suggestions UI ---
                                if (isSearching) ...[
                                  if (_suggestions.isNotEmpty)
                                    Expanded(
                                      child: ListView.builder(
                                        cacheExtent: 300,
                                        addAutomaticKeepAlives: false,
                                        addRepaintBoundaries: true,
                                        itemCount: _suggestions.length,
                                        itemBuilder: (context, index) {
                                          final item = _suggestions[index];
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            child: GestureDetector(
                                              onTap: () async {
                                                FocusScope.of(
                                                  context,
                                                ).unfocus();

                                                final description =
                                                    item['description'];
                                                _searchController.text =
                                                    description;

                                                setState(() {
                                                  _suggestions = [];
                                                });

                                                await _searchLocation(
                                                  description,
                                                );

                                                final placeDetailsUrl = Uri.parse(
                                                  "https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=$description&inputtype=textquery&fields=geometry&key=${dotenv.env['GOOGLE_MAPS_API_KEY']}",
                                                );

                                                final res = await http.get(
                                                  placeDetailsUrl,
                                                );
                                                final data = json.decode(
                                                  res.body,
                                                );

                                                final loc =
                                                    data['candidates'][0]['geometry']['location'];
                                                final dest = LatLng(
                                                  loc['lat'],
                                                  loc['lng'],
                                                );

                                                await _getRouteWithSteps(dest);
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
                                                    color: Colors.white
                                                        .withAlpha(20),
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
                                                        overflow: TextOverflow
                                                            .ellipsis,
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
                                ],
                                // --- End autocomplete UI ---
                              ],
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


class _DismissKeyboardLayer extends StatelessWidget {
  const _DismissKeyboardLayer();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
    );
  }
}