import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

GoogleMapController? globalMapController;
final ValueNotifier<LatLng?> userLocationNotifier = ValueNotifier(null);

class MyBackgroundContent extends StatefulWidget {
  final Set<Polyline> polylines;
  final Set<Marker> markers;

  const MyBackgroundContent({
    super.key,
    this.polylines = const {},
    this.markers = const {},
  });

  @override
  State<MyBackgroundContent> createState() => _MyBackgroundContentState();
}

class _MyBackgroundContentState extends State<MyBackgroundContent> {
  LatLng? currentLocation;
  Marker? _navigationMarker;
  StreamSubscription<Position>? _positionStream;

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

      if (mounted) {
        setState(() {
          _navigationMarker = widget.polylines.isNotEmpty
              ? Marker(
                  markerId: const MarkerId("nav_arrow"),
                  position: latLng,
                  anchor: const Offset(0.5, 0.5),
                  rotation: position.heading,
                  flat: true,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                )
              : null;
        });
      }

      // Move camera only when no navigation route is active
      if (globalMapController != null && widget.polylines.isEmpty) {
        globalMapController!.animateCamera(
          CameraUpdate.newLatLng(latLng),
        );
      }

      setState(() {});
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: currentLocation ?? const LatLng(22.5726, 88.3639),
        zoom: 15,
      ),
      onMapCreated: (controller) {
        globalMapController = controller;
      },
      rotateGesturesEnabled: true,
      myLocationEnabled: widget.polylines.isEmpty,
      myLocationButtonEnabled: widget.polylines.isEmpty,
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
    );
  }
}