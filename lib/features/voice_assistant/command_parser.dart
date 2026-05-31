enum VoiceCommand {
  navigate,
  call,
  playMusic,
  pauseMusic,
  nextTrack,
  previousTrack,
  batteryStatus,
  speed,
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
    if (RegExp(r'\b(emergency|help me|sos|crash)\b').hasMatch(text)) {
      return VoiceIntent(command: VoiceCommand.emergencySOS, rawText: rawText);
    }

    // 2. Navigation (Regex extraction)
    final navMatch = RegExp(r'\b(?:navigate(?: me)?|take me|directions|go)\s+to\s+(.+)\b').firstMatch(text);
    if (navMatch != null && navMatch.group(1) != null) {
      return VoiceIntent(
        command: VoiceCommand.navigate,
        params: {'place': navMatch.group(1)!.trim()},
        rawText: rawText,
      );
    }

    // 3. Calling (Regex extraction)
    final callMatch = RegExp(r'\b(?:call|phone|dial)\s+(.+)\b').firstMatch(text);
    if (callMatch != null && callMatch.group(1) != null) {
      return VoiceIntent(
        command: VoiceCommand.call,
        params: {'name': callMatch.group(1)!.trim()},
        rawText: rawText,
      );
    }

    // 4. Messaging
    if (RegExp(r'\b(?:read(?: my)? messages?|any new messages?)\b').hasMatch(text)) {
      return VoiceIntent(command: VoiceCommand.readMessages, rawText: rawText);
    }
    final replyMatch = RegExp(r'\b(?:reply|send(?: a)? message)\s+to\s+(.+)\b').firstMatch(text);
    if (replyMatch != null && replyMatch.group(1) != null) {
      return VoiceIntent(
        command: VoiceCommand.replyMessage,
        params: {'name': replyMatch.group(1)!.trim()},
        rawText: rawText,
      );
    }

    // 5. Music Controls
    if (RegExp(r'\b(play(?: music)?|resume(?: playback)?|start playing|put on music)\b').hasMatch(text)) {
      return VoiceIntent(command: VoiceCommand.playMusic, rawText: rawText);
    }
    if (RegExp(r'\b(pause(?: music)?|stop(?: music)?|halt|hold on)\b').hasMatch(text)) {
      return VoiceIntent(command: VoiceCommand.pauseMusic, rawText: rawText);
    }
    if (RegExp(r'\b(next(?: song| track)?|skip)\b').hasMatch(text)) {
      return VoiceIntent(command: VoiceCommand.nextTrack, rawText: rawText);
    }
    if (RegExp(r'\b(previous(?: song| track)?|go back)\b').hasMatch(text)) {
      return VoiceIntent(command: VoiceCommand.previousTrack, rawText: rawText);
    }

    // 6. System & Status
    if (RegExp(r'\b(battery(?: status| level)?|how much battery)\b').hasMatch(text)) {
      return VoiceIntent(command: VoiceCommand.batteryStatus, rawText: rawText);
    }
    if (RegExp(r'\b(speed|how fast|current speed|what\x27s my speed)\b').hasMatch(text)) {
      return VoiceIntent(command: VoiceCommand.speed, rawText: rawText);
    }
    if (RegExp(r'\b(volume up|louder|increase volume)\b').hasMatch(text)) {
      return VoiceIntent(command: VoiceCommand.volumeUp, rawText: rawText);
    }
    if (RegExp(r'\b(volume down|quieter|decrease volume)\b').hasMatch(text)) {
      return VoiceIntent(command: VoiceCommand.volumeDown, rawText: rawText);
    }
    if (RegExp(r'\b(time|what time is it|current time)\b').hasMatch(text)) {
      return VoiceIntent(command: VoiceCommand.time, rawText: rawText);
    }
    if (RegExp(r'\b(weather|is it raining|weather report)\b').hasMatch(text)) {
      return VoiceIntent(command: VoiceCommand.weather, rawText: rawText);
    }
    if (RegExp(r'\b(help|what can you do|commands)\b').hasMatch(text)) {
      return VoiceIntent(command: VoiceCommand.help, rawText: rawText);
    }

    // Unknown
    return VoiceIntent(command: VoiceCommand.unknown, rawText: rawText);
  }
}
