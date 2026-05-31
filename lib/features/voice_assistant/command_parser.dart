enum VoiceCommand {
  navigate,
  call,
  playMusic,
  pauseMusic,
  nextTrack,
  previousTrack,
  batteryStatus,
  speed,
  location,
  volumeUp,
  volumeDown,
  time,
  weather,
  help,
  readMessages,
  replyMessage,
  emergencySOS,
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

    // 1. Emergency (highest priority)
    if (text.contains('emergency') || text.contains('help me') || text.contains('sos') || text.contains('crash')) {
      return VoiceIntent(command: VoiceCommand.emergencySOS, rawText: rawText);
    }

    // 2. Navigation
    if (text.contains('navigate to') || text.contains('take me to') || text.contains('directions to') || text.contains('go to')) {
      final parts = text.split(' to ');
      if (parts.length > 1) {
        return VoiceIntent(command: VoiceCommand.navigate, params: {'place': parts.last.trim()}, rawText: rawText);
      }
    }

    // Location
    if (text.contains('where am i') || text.contains('my location') || text.contains('current location') || text.contains("what's my location")) {
      return VoiceIntent(command: VoiceCommand.location, rawText: rawText);
    }

    // 3. Calling
    if (text.contains('call ') || text.contains('phone ') || text.contains('dial ')) {
      final name = text.replaceFirst(RegExp(r'(call|phone|dial)\s+'), '').trim();
      return VoiceIntent(command: VoiceCommand.call, params: {'name': name}, rawText: rawText);
    }

    // 4. Messaging
    if (text.contains('read messages') || text.contains('read my messages') || text.contains('new messages')) {
      return VoiceIntent(command: VoiceCommand.readMessages, rawText: rawText);
    }
    if (text.contains('reply') || text.contains('send message')) {
      return VoiceIntent(command: VoiceCommand.replyMessage, rawText: rawText);
    }

    // 5. Music Controls
    if (text.contains('play music') || text.contains('resume music') || text.contains('start playing') || text.contains('put on music') || text == 'play' || text == 'resume') {
      return VoiceIntent(command: VoiceCommand.playMusic, rawText: rawText);
    }
    if (text.contains('pause music') || text.contains('stop music') || text.contains('halt music') || text == 'pause' || text == 'stop') {
      return VoiceIntent(command: VoiceCommand.pauseMusic, rawText: rawText);
    }
    if (text.contains('next song') || text.contains('next track') || text.contains('skip song') || text == 'next' || text == 'skip') {
      return VoiceIntent(command: VoiceCommand.nextTrack, rawText: rawText);
    }
    if (text.contains('previous song') || text.contains('previous track') || text.contains('go back') || text.contains('last song') || text == 'previous') {
      return VoiceIntent(command: VoiceCommand.previousTrack, rawText: rawText);
    }

    // 6. System & Status
    if (text.contains('battery')) {
      return VoiceIntent(command: VoiceCommand.batteryStatus, rawText: rawText);
    }
    if (text.contains('speed') || text.contains('how fast')) {
      return VoiceIntent(command: VoiceCommand.speed, rawText: rawText);
    }
    if (text.contains('volume up') || text.contains('louder') || text.contains('increase volume') || text.contains('turn the volume up')) {
      return VoiceIntent(command: VoiceCommand.volumeUp, rawText: rawText);
    }
    if (text.contains('volume down') || text.contains('quieter') || text.contains('decrease volume') || text.contains('turn the volume down')) {
      return VoiceIntent(command: VoiceCommand.volumeDown, rawText: rawText);
    }
    if (text.contains('time') || text.contains('what time is it')) {
      return VoiceIntent(command: VoiceCommand.time, rawText: rawText);
    }
    if (text.contains('weather') || text.contains('raining') || text.contains('temperature outside')) {
      return VoiceIntent(command: VoiceCommand.weather, rawText: rawText);
    }
    if (text.contains('help') || text.contains('what can you do') || text.contains('commands')) {
      return VoiceIntent(command: VoiceCommand.help, rawText: rawText);
    }

    // Unknown
    return VoiceIntent(command: VoiceCommand.unknown, rawText: rawText);
  }
}
