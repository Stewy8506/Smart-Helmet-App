import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';

GoogleMapController? globalMapController;
final ValueNotifier<LatLng?> userLocationNotifier = ValueNotifier(null);

class MyBackgroundContent extends StatefulWidget {
  final Set<Polyline> polylines;
  final Set<Marker> markers;
  final bool isPreview;

  const MyBackgroundContent({
    super.key,
    this.polylines = const {},
    this.markers = const {},
    this.isPreview = false,
  });

  @override
  State<MyBackgroundContent> createState() => _MyBackgroundContentState();
}

class _MyBackgroundContentState extends State<MyBackgroundContent> {
  LatLng? currentLocation;
  Marker? _navigationMarker;
  StreamSubscription<Position>? _positionStream;
  GoogleMapController? _mapController;
  LatLng? _lastCameraPosition;
  DateTime? _lastCameraUpdate;

  bool _initialLocationSet = false;
  LatLng? _pendingCamera;

  @override
  void initState() {
    super.initState();
    _listenServiceStatus();
    _initLocation();
  }

  void _listenServiceStatus() {
    Geolocator.getServiceStatusStream().listen((ServiceStatus status) {
      if (status == ServiceStatus.enabled) {
        _initLocation();
      }
    });
  }

  Future<LatLng?> _getInitialLatLng() async {
    // Try last known first (fast)
    final last = await Geolocator.getLastKnownPosition();
    if (last != null) {
      return LatLng(last.latitude, last.longitude);
    }

    // Fallback to current position with a short timeout
    try {
      final current = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 2),
      );
      return LatLng(current.latitude, current.longitude);
    } catch (_) {
      return null;
    }
  }

  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    // Preview mode: use last known location only (no live updates)
    if (widget.isPreview) {
      final latLng = await _getInitialLatLng();
      if (latLng != null) {
        currentLocation = latLng;
        userLocationNotifier.value = latLng;

        if (_mapController != null) {
          _mapController!.moveCamera(
            CameraUpdate.newLatLngZoom(latLng, 16),
          );
        } else {
          _pendingCamera = latLng;
        }

        if (mounted) setState(() {});
      }
      return;
    }

    // Get initial location once (fast + fallback)
    if (!_initialLocationSet) {
      final latLng = await _getInitialLatLng();
      if (latLng != null) {
        currentLocation = latLng;
        userLocationNotifier.value = latLng;
        _initialLocationSet = true;

        if (_mapController != null) {
          _mapController!.moveCamera(
            CameraUpdate.newLatLngZoom(latLng, 16),
          );
        } else {
          _pendingCamera = latLng;
        }

        if (mounted) setState(() {});
      }
    }

    _positionStream?.cancel();

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      final latLng = LatLng(position.latitude, position.longitude);

      currentLocation = latLng;
      userLocationNotifier.value = latLng;

      // Update navigation marker only when needed
      if (widget.polylines.isNotEmpty) {
        _navigationMarker = Marker(
          markerId: const MarkerId("nav_arrow"),
          position: latLng,
          anchor: const Offset(0.5, 0.5),
          rotation: position.heading,
          flat: true,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        );
      }

      // Throttle camera updates (reduce lag)
      final now = DateTime.now();
      final shouldUpdate = _lastCameraPosition == null ||
          Geolocator.distanceBetween(
                _lastCameraPosition!.latitude,
                _lastCameraPosition!.longitude,
                latLng.latitude,
                latLng.longitude,
              ) > (widget.isPreview ? 15 : 8) ||
          (_lastCameraUpdate == null ||
              now.difference(_lastCameraUpdate!).inMilliseconds > (widget.isPreview ? 1500 : 800));

      if (_mapController != null && (shouldUpdate || _lastCameraPosition == null)) {
        if (_lastCameraPosition != null &&
            Geolocator.distanceBetween(
              _lastCameraPosition!.latitude,
              _lastCameraPosition!.longitude,
              latLng.latitude,
              latLng.longitude,
            ) < 3) {
          return; // skip tiny movements
        }

        _lastCameraPosition = latLng;
        _lastCameraUpdate = now;

        _mapController!.moveCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: latLng,
              zoom: widget.isPreview ? 16 : 17,
              bearing: widget.isPreview ? 0 : position.heading,
              tilt: widget.isPreview ? 0 : 45,
            ),
          ),
        );
      }

      // Only rebuild when marker is used
      if (!widget.isPreview && widget.polylines.isNotEmpty && _navigationMarker != null && mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _positionStream = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: widget.isPreview && currentLocation != null
          ? SizedBox.expand(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  "https://maps.googleapis.com/maps/api/staticmap?"
                  "center=${currentLocation!.latitude},${currentLocation!.longitude}"
                  "&zoom=16"
                  "&size=640x640"
                  "&scale=2"
                  "&maptype=roadmap"
                  "&markers=anchor:center|icon:https://maps.google.com/mapfiles/ms/icons/blue-dot.png|${currentLocation!.latitude},${currentLocation!.longitude}"
                  "&style=element:geometry|color:0x212121"
                  "&style=element:labels.text.fill|color:0xa3a3a3"
                  "&style=element:labels.text.stroke|color:0x212121"
                  "&style=feature:road|element:geometry|color:0x2c2c2c"
                  "&style=feature:water|element:geometry|color:0x000000"
                  "&key=${dotenv.env['GOOGLE_MAPS_API_KEY']}",
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                    if (wasSynchronouslyLoaded) return child;
                    return AnimatedOpacity(
                      opacity: frame == null ? 0 : 1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      child: child,
                    );
                  },
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: Colors.black,
                    );
                  },
                ),
              ),
            )
          : GoogleMap(
        liteModeEnabled: widget.isPreview,
        initialCameraPosition: CameraPosition(
          target: currentLocation ?? const LatLng(0, 0),
          zoom: currentLocation != null ? 15 : 1,
        ),
        onMapCreated: (controller) {
          _mapController = controller;
          globalMapController = controller;

          final target = _pendingCamera ?? currentLocation;
          if (target != null) {
            controller.moveCamera(
              CameraUpdate.newLatLngZoom(
                target,
                widget.isPreview ? 16 : 17,
              ),
            );
            _pendingCamera = null;
          }
        },
        rotateGesturesEnabled: !widget.isPreview,
        scrollGesturesEnabled: !widget.isPreview,
        tiltGesturesEnabled: !widget.isPreview,
        zoomGesturesEnabled: !widget.isPreview,
        compassEnabled: !widget.isPreview,
        myLocationEnabled: true,
        myLocationButtonEnabled: !widget.isPreview,
        zoomControlsEnabled: false,
        mapType: MapType.normal,
        style: '''
[
  {"elementType":"geometry","stylers":[{"color":"#212121"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#a3a3a3"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#212121"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#2c2c2c"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]}
]
''',
        polylines: widget.polylines,
        markers: {
          if (widget.polylines.isNotEmpty && _navigationMarker != null)
            _navigationMarker!,
          ...widget.markers,
        },
      ),
    );
  }
}