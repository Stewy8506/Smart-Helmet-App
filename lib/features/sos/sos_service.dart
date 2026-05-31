import 'package:geolocator/geolocator.dart';
import 'package:telephony/telephony.dart';
import 'package:helmet_app/features/settings/settings_service.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

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
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
      );
      locationLink = "https://maps.google.com/?q=${pos.latitude},${pos.longitude}";
    } catch (e) {
      // ignore
    }

    final message = "EMERGENCY: I may have been in a crash. Here is my last known location: $locationLink";

    final contactNames = SettingsService.instance.emergencyContactNames;
    if (contactNames.isEmpty) return;

    final permission = await FlutterContacts.permissions.request(PermissionType.read);
    if (permission == PermissionStatus.granted) {
      final allContacts = await FlutterContacts.getAll(properties: {ContactProperty.name, ContactProperty.phone});
      
      for (final name in contactNames) {
        try {
          final c = allContacts.firstWhere((element) => element.displayName == name);
          if (c.phones.isNotEmpty) {
            final number = c.phones.first.number;
            await telephony.sendSms(
              to: number,
              message: message,
            );
          }
        } catch (e) {
          // ignore
        }
      }
    }
  }
}
