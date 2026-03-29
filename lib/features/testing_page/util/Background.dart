import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

GoogleMapController? globalMapController;
final ValueNotifier<LatLng?> userLocationNotifier = ValueNotifier(null);

class MyBackgroundContent extends StatefulWidget {
  const MyBackgroundContent({super.key});

  @override
  State<MyBackgroundContent> createState() => _MyBackgroundContentState();
}

class _MyBackgroundContentState extends State<MyBackgroundContent> {
  LatLng? currentLocation;
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

      // Move camera to user
      if (globalMapController != null) {
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
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
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
      markers: currentLocation != null
          ? {
              Marker(
                markerId: const MarkerId('user'),
                position: currentLocation!,
              )
            }
          : {},
    );
  }
}