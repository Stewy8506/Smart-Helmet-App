import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService instance = SettingsService._internal();

  SettingsService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Profile
  String get userName => _prefs?.getString('user_name') ?? 'Anuvab Das';
  Future<void> setUserName(String name) async {
    await _prefs?.setString('user_name', name);
  }

  String get userSubtitle => _prefs?.getString('user_subtitle') ?? 'Rider • Explorer';
  Future<void> setUserSubtitle(String subtitle) async {
    await _prefs?.setString('user_subtitle', subtitle);
  }

  // Contacts
  List<String> get emergencyContactNames {
    final list = _prefs?.getStringList('emergency_contacts');
    if (list == null || list.isEmpty) {
      // Default mock fallback until user configures
      return ["Sreyashi", "Sagnik RCCIIT", "Anwita", "Subhrodip RCCIIT", "mum"];
    }
    return list;
  }

  Future<void> setEmergencyContactNames(List<String> names) async {
    await _prefs?.setStringList('emergency_contacts', names);
  }
}
