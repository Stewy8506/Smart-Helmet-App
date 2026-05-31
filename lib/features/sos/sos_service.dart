import 'package:geolocator/geolocator.dart';
import 'package:telephony/telephony.dart';
import 'package:helmet_app/features/settings/settings_service.dart';

class SosService {
  static final SosService instance = SosService._internal();
  SosService._internal();

  final Telephony telephony = Telephony.instance;
  bool _isInitialized = false;

  Future<void> init() async {
    bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;
    if (permissionsGranted != null && permissionsGranted) {
      _isInitialized = true;
    }
  }

  Future<void> sendSosMessages() async {
    if (!_isInitialized) {
      await init();
      if (!_isInitialized) return;
    }

    String locationLink = "Location unavailable";
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      locationLink = "https://maps.google.com/?q=${pos.latitude},${pos.longitude}";
    } catch (e) {
      // ignore — send without location
    }

    final message =
        "EMERGENCY: I may have been in a crash. Here is my last known location: $locationLink";

    // Use stored phone numbers directly — no contact lookup needed
    final phones = SettingsService.instance.emergencyContactPhones;
    if (phones.isEmpty) return;

    for (final number in phones) {
      if (number.isEmpty) continue;
      try {
        await telephony.sendSms(to: number, message: message);
      } catch (e) {
        // ignore individual send failure, attempt the rest
      }
    }
  }
}
