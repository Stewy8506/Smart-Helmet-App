import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:helmet_app/features/settings/settings_service.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  List<Contact> _allContacts = [];
  List<String> _selectedNames = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _selectedNames = SettingsService.instance.emergencyContactNames.toList();

    // Use permission_handler if needed, but grid_screen uses this:
    final permission = await FlutterContacts.permissions.request(PermissionType.read);
    if (permission == PermissionStatus.granted) {
      _allContacts = await FlutterContacts.getAll(
        properties: {ContactProperty.name, ContactProperty.phone},
      );
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _toggleContact(String name) async {
    if (_selectedNames.contains(name)) {
      _selectedNames.remove(name);
    } else {
      _selectedNames.add(name);
    }
    await SettingsService.instance.setEmergencyContactNames(_selectedNames);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Emergency Contacts', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _allContacts.length,
              itemBuilder: (context, index) {
                final contact = _allContacts[index];
                final name = contact.displayName ?? 'Unknown';
                final isSelected = _selectedNames.contains(name);

                return ListTile(
                  title: Text(name, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    contact.phones.isNotEmpty ? contact.phones.first.number : 'No number',
                    style: const TextStyle(color: Colors.white54),
                  ),
                  trailing: Checkbox(
                    value: isSelected,
                    onChanged: (val) => _toggleContact(name),
                    activeColor: Colors.blueAccent,
                  ),
                  onTap: () => _toggleContact(name),
                );
              },
            ),
    );
  }
}
