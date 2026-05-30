import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'voice_assistant_service.dart';
import 'command_parser.dart';
import '../navigation/maps.dart';

class IntentRouter {
  final VoiceAssistantService _voiceService;
  
  IntentRouter(this._voiceService);

  Future<void> execute(VoiceIntent intent, BuildContext context) async {
    switch (intent.command) {
      case VoiceCommand.navigate:
        final place = intent.params['place'];
        if (place != null && place.isNotEmpty) {
          _voiceService.speak("Searching for $place");
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MapsScreen(initialDestination: place),
            ),
          );
        } else {
          _voiceService.speak("Where would you like to go?");
        }
        break;

      case VoiceCommand.call:
        final name = intent.params['name']?.toLowerCase();
        if (name != null && name.isNotEmpty) {
          _voiceService.speak("Calling $name");
          final permission = await FlutterContacts.permissions.request(PermissionType.read);
          if (permission == PermissionStatus.granted) {
            final contacts = await FlutterContacts.getAll(properties: {ContactProperty.name, ContactProperty.phone});
            Contact? match;
            for (var c in contacts) {
              if ((c.displayName ?? "").toLowerCase().contains(name)) {
                match = c;
                break;
              }
            }
            if (match != null && match.phones.isNotEmpty) {
              final phone = match.phones.first.number;
              final url = Uri.parse("tel:$phone");
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              }
            } else {
              _voiceService.speak("I couldn't find a contact named $name");
            }
          } else {
             _voiceService.speak("I don't have permission to access your contacts");
          }
        }
        break;

      case VoiceCommand.playMusic:
        _voiceService.speak("Resuming playback");
        // Audio control can be hooked up here
        break;

      case VoiceCommand.pauseMusic:
        _voiceService.speak("Pausing music");
        break;

      case VoiceCommand.nextTrack:
        _voiceService.speak("Skipping to next track");
        break;

      case VoiceCommand.previousTrack:
        _voiceService.speak("Going to previous track");
        break;

      case VoiceCommand.batteryStatus:
        _voiceService.speak("Phone battery is 78 percent. Helmet battery is 100 percent.");
        break;

      case VoiceCommand.speed:
        _voiceService.speak("Your current speed is 0 kilometers per hour.");
        break;

      case VoiceCommand.unknown:
        _voiceService.speak("Sorry, I didn't understand that command.");
        break;
    }
  }
}
