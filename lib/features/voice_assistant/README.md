# 🤖 Voice Assistant — Architecture & Developer Guide

> Comprehensive documentation for the Smart Helmet AI Voice Assistant module.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Components](#components)
4. [State Machine](#state-machine)
5. [Command Reference](#command-reference)
6. [Adding a New Voice Command](#adding-a-new-voice-command)
7. [Integration Points](#integration-points)
8. [Configuration](#configuration)
9. [Known Limitations](#known-limitations)
10. [Troubleshooting](#troubleshooting)

---

## Overview

The Voice Assistant provides **hands-free control** of the Smart Helmet App. It uses on-device speech recognition (no cloud AI) to transcribe voice commands, matches them against a rule-based command parser, and routes them to the appropriate app feature.

**Design principles:**
- **Safety first** — The rider should never need to look at or touch their phone
- **Local processing** — All parsing happens on-device for instant response (no network latency)
- **Graceful degradation** — Every failure path has a spoken TTS response
- **Zero configuration** — Microphone permissions are requested automatically; no setup needed

**Tech stack:**
- `speech_to_text` ^7.3.0 — On-device speech recognition (Google STT on Android)
- `flutter_tts` ^4.2.5 — Text-to-speech for all voice responses
- `flutter_contacts` ^2.2.0 — Contact lookup for call commands
- `url_launcher` ^6.2.5 — Phone dialer integration

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        UI LAYER                                 │
│                                                                 │
│  ┌──────────┐    tap    ┌───────────────┐                       │
│  │ VoiceFAB │ ─────────▶│ VoiceOverlay  │                       │
│  │(mic btn) │           │(full-screen)  │                       │
│  └──────────┘           └───────┬───────┘                       │
│                                 │                               │
│                         listens to state                        │
│                         changes via                             │
│                         ValueNotifier                           │
├─────────────────────────┬───────┴───────────────────────────────┤
│                    SERVICE LAYER                                │
│                                                                 │
│  ┌─────────────────────────────────────┐                        │
│  │     VoiceAssistantService           │                        │
│  │     (Singleton)                     │                        │
│  │                                     │                        │
│  │  ┌─────────────┐ ┌──────────────┐   │                        │
│  │  │ SpeechToText│ │  FlutterTts  │   │                        │
│  │  └─────────────┘ └──────────────┘   │                        │
│  │                                     │                        │
│  │  state: ValueNotifier<VoiceState>   │                        │
│  │  recognizedText: ValueNotifier<Str> │                        │
│  └─────────────────────────────────────┘                        │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                    LOGIC LAYER                                  │
│                                                                 │
│  ┌──────────────┐         ┌──────────────┐                      │
│  │CommandParser │────────▶│ IntentRouter  │                      │
│  │(pure func)   │ VoiceIntent   │                               │
│  └──────────────┘         └──────┬───────┘                      │
│                                  │                              │
├──────────────────────────────────┼──────────────────────────────┤
│                    FEATURE LAYER │                               │
│                                  ▼                              │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐           │
│  │MapsScreen│ │Contacts  │ │AudioSvc  │ │Geolocator│           │
│  │(navigate)│ │(call)    │ │(music)   │ │(speed)   │           │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘           │
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow

1. User taps `VoiceFAB` → `VoiceAssistantService.startListening()`
2. `VoiceOverlay` opens as a full-screen dialog
3. `SpeechToText` streams partial results → `recognizedText` ValueNotifier updates
4. On silence timeout or STT "notListening" → state transitions to `processing`
5. `VoiceOverlay._onStateChange()` detects `processing` state
6. Calls `CommandParser.parse(rawText)` → returns `VoiceIntent`
7. Calls `IntentRouter.execute(intent, context)` → dispatches to feature
8. `IntentRouter` calls `VoiceAssistantService.speak(response)` → state becomes `speaking`
9. TTS completion handler → state returns to `idle`
10. `VoiceOverlay` detects `idle` → auto-pops itself

---

## Components

### VoiceAssistantService

**File:** `voice_assistant_service.dart`  
**Pattern:** Singleton (`VoiceAssistantService.instance`)

**Responsibilities:**
- Initialize and manage `SpeechToText` and `FlutterTts` instances
- Expose reactive state via `ValueNotifier<VoiceState>`
- Handle silence detection with configurable timeout (5s)
- Provide `startListening()`, `stopListening()`, `speak()` API

**Key configuration:**
```dart
// STT settings
listenFor: Duration(seconds: 15),   // Max listen duration
pauseFor: Duration(seconds: 3),     // Pause detection
partialResults: true,                // Stream partial transcription
listenMode: ListenMode.confirmation, // Single utterance mode

// TTS settings
language: "en-US",
speechRate: 0.5,                     // Half speed for clarity
volume: 1.0,
pitch: 1.0,
```

---

### CommandParser

**File:** `command_parser.dart`  
**Pattern:** Static utility class (pure functions)

**Input:** Raw transcription string  
**Output:** `VoiceIntent` with `command` enum + `params` map

**Matching strategy:**
1. Normalize input: `trim()` + `toLowerCase()`
2. Check prefixes in priority order (navigate → call → music → status)
3. Extract parameters by substring after the matched prefix
4. Return `VoiceCommand.unknown` as fallback

---

### IntentRouter

**File:** `intent_router.dart`  
**Pattern:** Command dispatcher

**Responsibilities:**
- Switch on `VoiceIntent.command`
- Execute the appropriate app feature (Navigator, Contacts, etc.)
- Always provide TTS feedback to the user
- Handle errors gracefully with spoken error messages

---

### VoiceFAB

**File:** `widgets/voice_fab.dart`  
**Pattern:** Stateful widget with animation

**Visual states:**

| State | Icon | Color | Animation |
|-------|------|-------|-----------|
| Idle | `mic_none` | White | None |
| Listening | `mic` | Red | Pulsing scale (1.0 → 1.15) with red glow |
| Processing | Spinner | White | CircularProgressIndicator |
| Speaking | `volume_up` | White | None |

**Self-healing:** Tapping while in `processing` or `speaking` force-resets to `idle`.

---

### VoiceOverlay

**File:** `widgets/voice_overlay.dart`  
**Pattern:** Full-screen dialog via `showGeneralDialog`

**Features:**
- Dark scrim background (opacity 220/255)
- Large pulsing mic icon with glow shadow
- Real-time transcription text (updates live as STT processes)
- State-appropriate status text: "Listening...", "Processing...", "Error occurred"
- "Tap anywhere to cancel" hint
- Auto-dismiss on state returning to idle

---

## State Machine

```
                 ┌──────────────────────────┐
                 │                          │
                 ▼                          │
          ┌──────────┐                      │
     ┌───▶│   IDLE   │◀─── TTS complete ────┘
     │    └──────────┘
     │         │
     │         │ startListening()
     │         ▼
     │    ┌──────────────┐
     │    │  LISTENING   │◀──── partial results stream
     │    └──────────────┘
     │         │
     │         │ silence timeout (5s)
     │         │ or STT "notListening"
     │         │ or manual stopListening()
     │         ▼
     │    ┌──────────────┐
     │    │  PROCESSING  │ ──── CommandParser.parse()
     │    └──────────────┘      IntentRouter.execute()
     │         │
     │         │ speak(response)
     │         ▼
     │    ┌──────────────┐
     │    │   SPEAKING   │ ──── FlutterTts.speak()
     │    └──────────────┘
     │         │
     │         │ TTS completion handler
     │         │
     │         ▼
     │    ┌──────────────┐
     └────│   (→ IDLE)   │
          └──────────────┘

     Error path:
     Any state ──▶ ERROR ──▶ speak(errorMsg) ──▶ SPEAKING ──▶ IDLE
```

**Timeout values:**
- Silence timeout: **5 seconds** (no speech detected → auto-process)
- Max listen duration: **15 seconds** (STT engine limit)
- Pause detection: **3 seconds** (gap in speech → stop listening)

---

## Command Reference

### Navigation Commands
```
"Navigate to [destination]"
"Take me to [destination]"
"Directions to [destination]"
"Go to [destination]"
```
**Action:** Pushes `MapsScreen(initialDestination: destination)` onto the navigation stack. The Maps screen auto-populates the search bar and fetches suggestions.

### Call Commands
```
"Call [contact name]"
"Phone [contact name]"
"Dial [contact name]"
```
**Action:** Requests contact permission, searches by display name (case-insensitive partial match), dials the first phone number via `url_launcher`.

### Music Commands
```
"Play music" / "Resume music" / "Play" / "Resume"
"Pause music" / "Stop music" / "Pause" / "Stop"
"Next song" / "Skip" / "Next track" / "Next"
"Previous song" / "Go back" / "Previous track" / "Previous"
```
**Action:** Currently stubs — speaks acknowledgment only. Planned: wire to `AudioHandler`.

### Status Commands
```
"Battery status" / "Battery level" / "How much battery" / "Battery"
"How fast" / "Current speed" / "What's my speed" / "Speed"
```
**Action:** Currently stubs — returns hardcoded values. Planned: read real battery via `battery_plus`, real speed via `Geolocator`.

---

## Adding a New Voice Command

Follow these 4 steps to add a new command to the voice assistant:

### Step 1: Add the command enum

In `command_parser.dart`, add a new value to `VoiceCommand`:

```dart
enum VoiceCommand {
  navigate,
  call,
  // ... existing commands
  myNewCommand,    // ← ADD THIS
  unknown,
}
```

### Step 2: Add parsing rules

In `CommandParser.parse()`, add a new matching block **before** the `unknown` return:

```dart
// My new feature
if (text.contains('trigger phrase') || text.startsWith('do something ')) {
  String param = '';
  if (text.startsWith('do something ')) {
    param = text.substring('do something '.length);
  }
  return VoiceIntent(
    command: VoiceCommand.myNewCommand,
    params: {'param': param.trim()},
    rawText: rawText,
  );
}
```

**Tips:**
- Use `startsWith()` for commands with a trailing parameter
- Use `contains()` for status-check commands
- Use exact `==` for single-word commands
- Always normalize: the input is already `trim().toLowerCase()`

### Step 3: Handle the command in IntentRouter

In `intent_router.dart`, add a new case to the switch:

```dart
case VoiceCommand.myNewCommand:
  final param = intent.params['param'];
  if (param != null && param.isNotEmpty) {
    _voiceService.speak("Executing my new feature for $param");
    // Call your feature's API here
  } else {
    _voiceService.speak("What should I do?");
  }
  break;
```

### Step 4: Test

1. Hot restart the app (`R` in terminal)
2. Tap the mic button
3. Speak your trigger phrase
4. Verify the correct action executes and TTS responds

---

## Integration Points

The voice assistant connects to these existing app features:

| Feature | How It's Called | File | Line |
|---------|----------------|------|------|
| Navigation | `Navigator.push(MapsScreen(initialDestination:))` | `intent_router.dart` | 20-25 |
| Contact Search | `FlutterContacts.getAll()` | `intent_router.dart` | 37 |
| Phone Dialer | `launchUrl(Uri.parse("tel:$phone"))` | `intent_router.dart` | 49 |
| TTS Output | `VoiceAssistantService.speak()` | `voice_assistant_service.dart` | 97 |
| Maps Search | `MapsScreen._fetchSuggestions()` (via initialDestination) | `maps.dart` | 57-63 |

---

## Configuration

### Android Permissions

The following permission is required in `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
```

This is automatically included by the `speech_to_text` package.

### TTS Language

Default: `en-US`. To change, modify `VoiceAssistantService.initialize()`:

```dart
await _tts.setLanguage("en-IN");  // Indian English
```

Available languages depend on the device's installed TTS engines.

### Timeouts

All timeout values are in `VoiceAssistantService`:

| Timeout | Default | Location |
|---------|---------|----------|
| Silence timer | 5 seconds | `_resetSilenceTimer()` |
| Max listen duration | 15 seconds | `startListening()` |
| Pause detection | 3 seconds | `startListening()` |

---

## Known Limitations

1. **English only** — CommandParser uses English keywords. Multilingual support requires new parsing rules per language.

2. **Exact phrase matching** — The parser uses prefix/contains matching, not fuzzy NLP. "Take me to the mall" works, but "I want to go shopping at the mall" does not.

3. **No conversation context** — Each command is stateless. The assistant doesn't remember previous interactions or support follow-up questions.

4. **Music controls are stubs** — Play/pause/skip commands only speak acknowledgment; they don't control actual playback.

5. **Battery/speed are hardcoded** — Values are static, not read from real sensors.

6. **Single utterance only** — The assistant processes one command per activation. Multi-command chains ("navigate to the mall and call John") are not supported.

7. **No wake word** — Requires manual tap to activate. Always-on "Hey Helmet" wake word is not implemented.

8. **No offline fallback** — `SpeechToText` on Android requires Google services and may need a network connection for some recognition models.

9. **VoiceFAB can get stuck** — If the overlay is dismissed during processing, the state may get stuck. Tapping the FAB will force-reset it.

---

## Troubleshooting

### "No liquid glass renderer found in context"
The `VoiceFAB` originally used `LiquidGlass` for its visual style. This was replaced with a standard `BackdropFilter` + `ClipOval` to avoid context issues. If you see this error, ensure `VoiceFAB` is not wrapped in `LiquidGlass`.

### Microphone not working
1. Check app permissions in Android Settings → Apps → Smart Helmet → Permissions
2. Ensure no other app is using the microphone
3. Try `VoiceAssistantService.instance.initialize()` manually and check the return value

### State stuck in "processing"
Tap the VoiceFAB button — it will force-reset the state to `idle`. This is a known edge case when the overlay is dismissed mid-flow.

### TTS not speaking
1. Check device volume (media volume, not ringer)
2. Verify a TTS engine is installed: Android Settings → Accessibility → Text-to-speech
3. Try `FlutterTts().speak("test")` in isolation

### STT returns empty text
1. The silence timer may have fired before the user spoke
2. Increase `pauseFor` duration in `startListening()`
3. Check for network connectivity (Google STT may require it)

---

## Future Work

- [ ] Wire music commands to real `AudioHandler`
- [ ] Read real phone battery via `battery_plus`
- [ ] Read GPS speed from `Geolocator.getPositionStream()`
- [ ] Add command hint chips to `VoiceOverlay`
- [ ] Crash detection & emergency SOS
- [ ] Speed limit warning system
- [ ] Nearest fuel/charging station finder
- [ ] Weather alerts during navigation
- [ ] Hands-free message read & reply
- [ ] Wake word activation ("Hey Helmet")
- [ ] Multi-language support
- [ ] Gemini AI integration for natural language understanding
