import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:helmet_app/features/spotify/spotify_service.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:intl/intl.dart';
import 'package:helmet_app/features/weather/weather_service.dart';
import 'voice_assistant_service.dart';
import 'command_parser.dart';
import '../navigation/maps.dart';
import 'package:helmet_app/features/sos/crash_overlay.dart';
import 'package:telephony/telephony.dart';

class IntentRouter {
  final VoiceAssistantService _voiceService;
  
  IntentRouter(this._voiceService);

  Future<void> execute(VoiceIntent intent, BuildContext context) async {
    // Check if we are awaiting dictation for an SMS reply
    if (_voiceService.conversationContext['awaitingDictation'] == true) {
      final address = _voiceService.conversationContext['lastSmsAddress'] as String?;
      if (address != null && intent.rawText.isNotEmpty) {
        _voiceService.speak("Sending: ${intent.rawText}");
        try {
          await Telephony.instance.sendSms(to: address, message: intent.rawText);
        } catch (e) {
          _voiceService.speak("Failed to send message.");
        }
      } else {
        _voiceService.speak("Cancelling reply.");
      }
      _voiceService.conversationContext['awaitingDictation'] = false;
      return;
    }

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
        await SpotifyService.instance.play();
        break;

      case VoiceCommand.pauseMusic:
        _voiceService.speak("Pausing music");
        await SpotifyService.instance.pause();
        break;

      case VoiceCommand.nextTrack:
        _voiceService.speak("Skipping to next track");
        await SpotifyService.instance.skipToNext();
        break;

      case VoiceCommand.previousTrack:
        _voiceService.speak("Going to previous track");
        await SpotifyService.instance.skipToPrevious();
        break;

      case VoiceCommand.switchSpotify:
      case VoiceCommand.switchLocal:
        _voiceService.speak("I only play music from Spotify now.");
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

      case VoiceCommand.location:
        _voiceService.speak("Fetching your location.");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MapsScreen(),
          ),
        );
        break;

      case VoiceCommand.volumeUp:
        _voiceService.speak("Increasing volume");
        final current = await FlutterVolumeController.getVolume() ?? 0.5;
        await FlutterVolumeController.setVolume(current + 0.2);
        break;

      case VoiceCommand.volumeDown:
        _voiceService.speak("Decreasing volume");
        final current = await FlutterVolumeController.getVolume() ?? 0.5;
        await FlutterVolumeController.setVolume(current - 0.2);
        break;

      case VoiceCommand.time:
        final now = DateTime.now();
        final timeString = DateFormat('h:mm a').format(now);
        _voiceService.speak("It is currently $timeString");
        break;

      case VoiceCommand.weather:
        _voiceService.speak("Checking the weather...");
        final weatherString = await WeatherService.getCurrentWeather();
        _voiceService.speak(weatherString);
        break;

      case VoiceCommand.help:
        _voiceService.speak("You can ask me to navigate, call someone, play music, or check your speed and battery.");
        break;

      case VoiceCommand.readMessages:
        try {
          final telephony = Telephony.instance;
          final messages = await telephony.getInboxSms(
            columns: [SmsColumn.ADDRESS, SmsColumn.BODY],
            sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
          );

          if (messages.isNotEmpty) {
            final latest = messages.first;
            _voiceService.conversationContext['lastSmsAddress'] = latest.address;
            _voiceService.speak("You have a message from ${latest.address}. It says: ${latest.body}. Would you like to reply?", expectFollowUp: true);
          } else {
            _voiceService.speak("You have no new messages.");
          }
        } catch (e) {
          debugPrint("SMS read error: $e");
          _voiceService.speak("I couldn't read your messages. Please check SMS permissions.");
        }
        break;

      case VoiceCommand.replyMessage:
        final address = _voiceService.conversationContext['lastSmsAddress'] as String?;
        if (address != null && address.isNotEmpty) {
          _voiceService.conversationContext['awaitingDictation'] = true;
          _voiceService.speak("What should I say?", expectFollowUp: true);
        } else {
          _voiceService.speak("There is no recent message to reply to.");
        }
        break;

      case VoiceCommand.emergencySOS:
        _voiceService.speak("Crash alert triggered. Tap cancel to stop the SOS.");
        Navigator.push(
          context,
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (BuildContext context, _, animation) => const CrashOverlay(),
          ),
        );
        break;

      case VoiceCommand.unknown:
        _voiceService.speak("Sorry, I didn't understand that command.");
        break;
    }
  }
}
