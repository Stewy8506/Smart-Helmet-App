import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:helmet_app/features/voice_assistant/audio_bridge.dart';
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
        await AudioBridge.instance.play();
        break;

      case VoiceCommand.pauseMusic:
        _voiceService.speak("Pausing music");
        await AudioBridge.instance.pause();
        break;

      case VoiceCommand.nextTrack:
        _voiceService.speak("Skipping to next track");
        await AudioBridge.instance.skipToNext();
        break;

      case VoiceCommand.previousTrack:
        _voiceService.speak("Going to previous track");
        await AudioBridge.instance.skipToPrevious();
        break;

      case VoiceCommand.batteryStatus:
        final level = await Battery().batteryLevel;
        _voiceService.speak("Phone battery is $level percent. Helmet battery is 100 percent.");
        break;

      case VoiceCommand.speed:
        try {
          final pos = await Geolocator.getLastKnownPosition();
          if (pos != null) {
            final speedKmh = (pos.speed * 3.6).round();
            _voiceService.speak("Your current speed is $speedKmh kilometers per hour.");
          } else {
            _voiceService.speak("I don't have a GPS signal right now.");
          }
        } catch (e) {
          _voiceService.speak("I couldn't get your speed.");
        }
        break;

      case VoiceCommand.unknown:
        _voiceService.speak("Sorry, I didn't understand that command.");
        break;
    }
  }
}
