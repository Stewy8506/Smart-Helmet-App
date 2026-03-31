import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

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
      final lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        final latLng = LatLng(lastPosition.latitude, lastPosition.longitude);
        currentLocation = latLng;
        userLocationNotifier.value = latLng;

        if (_mapController != null) {
          _mapController!.moveCamera(
            CameraUpdate.newLatLngZoom(latLng, 16),
          );
        }

        if (mounted) setState(() {});
      }
      return;
    }

    _positionStream?.cancel();

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
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

      if (_mapController != null && shouldUpdate) {
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
      if (!widget.isPreview && widget.polylines.isNotEmpty && mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: currentLocation ?? const LatLng(0, 0),
          zoom: currentLocation != null ? 15 : 1,
        ),
        onMapCreated: (controller) {
          _mapController = controller;
          globalMapController = controller;

          if (currentLocation != null) {
            controller.moveCamera(
              CameraUpdate.newLatLngZoom(
                currentLocation!,
                widget.isPreview ? 16 : 17,
              ),
            );
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
  {"elementType":"labels.text.stroke","stylers":[{"color":"#21212130"}]},
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