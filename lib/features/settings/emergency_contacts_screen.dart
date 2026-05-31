import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:helmet_app/features/settings/settings_service.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  List<Contact> _allContacts = [];
  List<WhitelistContact> _selected = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _selected = SettingsService.instance.contactWhitelist.toList();

    final permission = await FlutterContacts.permissions.request(PermissionType.read);
    if (permission == PermissionStatus.granted) {
      _allContacts = await FlutterContacts.getAll(
        properties: {ContactProperty.name, ContactProperty.phone},
      );
    }
    if (mounted) setState(() => _isLoading = false);
  }

  bool _isSelected(Contact contact) {
    final phone = contact.phones.isNotEmpty
        ? _normalize(contact.phones.first.number)
        : '';
    return _selected.any((c) => _normalize(c.phone) == phone);
  }

  void _toggle(Contact contact) async {
    if (contact.phones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This contact has no phone number.')),
      );
      return;
    }

    final phone = _normalize(contact.phones.first.number);
    final name = contact.displayName ?? 'Unknown';

    if (_isSelected(contact)) {
      _selected.removeWhere((c) => _normalize(c.phone) == phone);
    } else {
      _selected.add(WhitelistContact(name: name, phone: contact.phones.first.number));
    }

    await SettingsService.instance.setContactWhitelist(_selected);
    if (mounted) setState(() {});
  }

  String _normalize(String phone) =>
      phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');

  @override
  Widget build(BuildContext context) {
    final filteredContacts = _allContacts.where((contact) {
      final nameMatches = contact.displayName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
      final phoneMatches = contact.phones.any((phone) => phone.number.contains(_searchQuery));
      return nameMatches || phoneMatches;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: Text(
          'Emergency Contacts',
          style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withAlpha(180),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_selected.length} selected',
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
          : _allContacts.isEmpty
              ? _buildEmptyState('No contacts found.\nPlease grant contacts permission in Settings.')
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search contacts...',
                          hintStyle: const TextStyle(color: Colors.white54),
                          prefixIcon: const Icon(Icons.search, color: Colors.white54),
                          filled: true,
                          fillColor: Colors.white10,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),
                    if (_selected.isEmpty)
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withAlpha(40),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.redAccent.withAlpha(80)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'No contacts selected. Select contacts who will receive your crash SOS alert.',
                                style: GoogleFonts.montserrat(
                                  color: Colors.redAccent,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: filteredContacts.isEmpty
                          ? Center(
                              child: Text(
                                'No matching contacts found',
                                style: GoogleFonts.montserrat(color: Colors.white54),
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredContacts.length,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemBuilder: (context, index) {
                                final contact = filteredContacts[index];
                          final selected = _isSelected(contact);
                          final phone = contact.phones.isNotEmpty
                              ? contact.phones.first.number
                              : null;

                          return ListTile(
                            onTap: () => _toggle(contact),
                            leading: CircleAvatar(
                              backgroundColor: selected
                                  ? Colors.redAccent.withAlpha(180)
                                  : Colors.white10,
                              child: Text(
                                (contact.displayName ?? '?').isNotEmpty
                                    ? (contact.displayName ?? '?')[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            title: Text(
                              contact.displayName ?? 'Unknown',
                              style: GoogleFonts.montserrat(color: Colors.white),
                            ),
                            subtitle: Text(
                              phone ?? 'No number',
                              style: GoogleFonts.montserrat(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            trailing: Checkbox(
                              value: selected,
                              onChanged: phone != null ? (_) => _toggle(contact) : null,
                              activeColor: Colors.redAccent,
                              checkColor: Colors.white,
                              side: const BorderSide(color: Colors.white38),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.contacts_outlined, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
