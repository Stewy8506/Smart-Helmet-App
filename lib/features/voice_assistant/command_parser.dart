enum VoiceCommand {
  navigate,
  call,
  playMusic,
  pauseMusic,
  nextTrack,
  previousTrack,
  batteryStatus,
  speed,
  unknown,
}

class VoiceIntent {
  final VoiceCommand command;
  final Map<String, String> params;
  final String rawText;

  VoiceIntent({
    required this.command,
    this.params = const {},
    required this.rawText,
  });
}

class CommandParser {
  static VoiceIntent parse(String rawText) {
    final text = rawText.trim().toLowerCase();

    // Navigation
    if (text.startsWith('navigate to ') ||
        text.startsWith('take me to ') ||
        text.startsWith('directions to ') ||
        text.startsWith('go to ')) {
      String place = '';
      if (text.startsWith('navigate to ')) {
        place = text.substring('navigate to '.length);
      } else if (text.startsWith('take me to ')) {
        place = text.substring('take me to '.length);
      } else if (text.startsWith('directions to ')) {
        place = text.substring('directions to '.length);
      } else if (text.startsWith('go to ')) {
        place = text.substring('go to '.length);
      }
      
      if (place.isNotEmpty) {
        return VoiceIntent(
          command: VoiceCommand.navigate,
          params: {'place': place.trim()},
          rawText: rawText,
        );
      }
    }

    // Call
    if (text.startsWith('call ') ||
        text.startsWith('phone ') ||
        text.startsWith('dial ')) {
      String name = '';
      if (text.startsWith('call ')) {
        name = text.substring('call '.length);
      } else if (text.startsWith('phone ')) {
        name = text.substring('phone '.length);
      } else if (text.startsWith('dial ')) {
        name = text.substring('dial '.length);
      }
      
      if (name.isNotEmpty) {
        return VoiceIntent(
          command: VoiceCommand.call,
          params: {'name': name.trim()},
          rawText: rawText,
        );
      }
    }

    // Music control
    if (text == 'play music' || text == 'resume music' || text == 'play' || text == 'resume') {
      return VoiceIntent(command: VoiceCommand.playMusic, rawText: rawText);
    }
    if (text == 'pause music' || text == 'stop music' || text == 'pause' || text == 'stop') {
      return VoiceIntent(command: VoiceCommand.pauseMusic, rawText: rawText);
    }
    if (text == 'next song' || text == 'skip' || text == 'next track' || text == 'next') {
      return VoiceIntent(command: VoiceCommand.nextTrack, rawText: rawText);
    }
    if (text == 'previous song' || text == 'go back' || text == 'previous track' || text == 'previous') {
      return VoiceIntent(command: VoiceCommand.previousTrack, rawText: rawText);
    }

    // Status
    if (text.contains('battery status') || text.contains('battery level') || text.contains('how much battery') || text == 'battery') {
      return VoiceIntent(command: VoiceCommand.batteryStatus, rawText: rawText);
    }
    if (text.contains('how fast') || text.contains('current speed') || text.contains("what's my speed") || text == 'speed') {
      return VoiceIntent(command: VoiceCommand.speed, rawText: rawText);
    }

    // Unknown
    return VoiceIntent(command: VoiceCommand.unknown, rawText: rawText);
  }
}
