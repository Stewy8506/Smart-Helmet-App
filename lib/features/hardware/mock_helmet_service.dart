import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

class HelmetTelemetry {
  final int heartRate;
  final double temperature;
  final int batteryPercent;

  HelmetTelemetry({
    required this.heartRate,
    required this.temperature,
    required this.batteryPercent,
  });
}

class MockHelmetService {
  static final MockHelmetService instance = MockHelmetService._internal();
  MockHelmetService._internal();

  final ValueNotifier<HelmetTelemetry> telemetry = ValueNotifier(HelmetTelemetry(
    heartRate: 75,
    temperature: 36.5,
    batteryPercent: 100,
  ));

  Timer? _timer;
  final Random _random = Random();
  double _currentTemp = 36.5;
  int _currentHR = 75;
  double _battFloat = 100.0;

  void start() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _currentHR += _random.nextInt(5) - 2;
      if (_currentHR < 60) _currentHR = 60;
      if (_currentHR > 140) _currentHR = 140;

      _currentTemp += (_random.nextDouble() * 0.2) - 0.1;
      if (_currentTemp < 35.0) _currentTemp = 35.0;
      if (_currentTemp > 39.0) _currentTemp = 39.0;

      _battFloat -= 0.05; // faster drain for demo
      if (_battFloat < 0) _battFloat = 0;

      telemetry.value = HelmetTelemetry(
        heartRate: _currentHR,
        temperature: double.parse(_currentTemp.toStringAsFixed(1)),
        batteryPercent: _battFloat.toInt(),
      );
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
