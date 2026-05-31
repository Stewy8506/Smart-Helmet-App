import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// A single whitelisted contact entry (name + phone number).
class WhitelistContact {
  final String name;
  final String phone;

  const WhitelistContact({required this.name, required this.phone});

  Map<String, String> toMap() => {'name': name, 'phone': phone};

  factory WhitelistContact.fromMap(Map<String, dynamic> map) {
    return WhitelistContact(
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
    );
  }

  String toJson() => jsonEncode(toMap());
  factory WhitelistContact.fromJson(String json) =>
      WhitelistContact.fromMap(jsonDecode(json) as Map<String, dynamic>);
}

class SettingsService {
  static final SettingsService instance = SettingsService._internal();

  SettingsService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Profile
  String get userName => _prefs?.getString('user_name') ?? 'Rider';
  Future<void> setUserName(String name) async {
    await _prefs?.setString('user_name', name);
  }

  String get userSubtitle => _prefs?.getString('user_subtitle') ?? 'Rider • Explorer';
  Future<void> setUserSubtitle(String subtitle) async {
    await _prefs?.setString('user_subtitle', subtitle);
  }

  // --- Contact Whitelist (stored by name + phone number) ---

  /// Returns the full whitelist entries with name and phone.
  List<WhitelistContact> get contactWhitelist {
    final list = _prefs?.getStringList('contact_whitelist_v2');
    if (list == null || list.isEmpty) return [];
    return list
        .map((e) {
          try {
            return WhitelistContact.fromJson(e);
          } catch (_) {
            return null;
          }
        })
        .whereType<WhitelistContact>()
        .toList();
  }

  Future<void> setContactWhitelist(List<WhitelistContact> contacts) async {
    final jsonList = contacts.map((c) => c.toJson()).toList();
    await _prefs?.setStringList('contact_whitelist_v2', jsonList);
  }

  /// Convenience: just the display names for UI use.
  List<String> get emergencyContactNames =>
      contactWhitelist.map((c) => c.name).toList();

  /// Convenience: just the phone numbers for SMS dispatch.
  List<String> get emergencyContactPhones =>
      contactWhitelist.map((c) => c.phone).toList();
}
