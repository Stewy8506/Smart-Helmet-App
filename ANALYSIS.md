# 🪖 Smart Helmet App — Deep Codebase Analysis

> **Date**: May 30, 2026 | **Codebase**: `Smart-Helmet-App` | **Last Updated**: May 30, 2026

---

## 1. What Is This Project?

The **Smart Helmet App** is a **Flutter-based mobile companion application** for a custom IoT smart helmet powered by ESP32/ESP32-S3 microcontrollers. It is designed for motorcycle riders and aims to provide real-time helmet connectivity, navigation, audio control, call handling, voice assistant, and safety monitoring.

### Feature Status Matrix

| Feature | Status | Description |
|---------|--------|-------------|
| 🏍️ Dashboard | ✅ Built | Helmet status, battery ring, trip stats, last route map |
| 🗺️ Navigation | ✅ Built | Full Google Maps navigation with turn-by-turn TTS, route preview, autocomplete |
| 📞 Calls | ✅ Built | Contact list with tap-to-call via device phone dialer |
| 🎵 Music Control | ⚠️ Partial | UI built, `AudioService` wired but handler is a stub |
| 🔋 Battery Monitor | ⚠️ Hardcoded | Static 78%/100% values, no real Bluetooth data |
| 🔐 Authentication | ⚠️ Placeholder | Login/Signup UI exists, Firebase not integrated |
| 🎬 Onboarding | ✅ Built | Scroll-driven video onboarding |
| ⚙️ Settings | ⚠️ Shell | UI tiles only, no settings logic |
| 👤 Profile | ⚠️ Static | Hardcoded name/avatar/stats |
| 🤖 Voice Assistant | ✅ Built (v1) | Hands-free voice commands for navigation, calls, music, status |
| 📡 Bluetooth/BLE | ❌ Missing | No Bluetooth code exists |

**Key takeaway**: The app has progressed beyond a UI prototype. Google Maps navigation and the AI Voice Assistant are both fully functional, with music/battery/speed commands operating as stubs pending real data integration.

---

## 2. Tech Stack & Dependencies

- **Framework**: Flutter (Dart SDK ^3.11.0)
- **UI**: Material Design 3, dark theme, Liquid Glass glassmorphism effects
- **Maps**: Google Maps Flutter + Geolocator + Directions/Places APIs
- **Voice (STT)**: `speech_to_text` — Used by `VoiceAssistantService` for speech recognition
- **Voice (TTS)**: `flutter_tts` — Used for navigation instructions AND voice assistant responses
- **Auth**: Firebase Core/Auth (declared but UNUSED)
- **Audio**: `audio_service` (stub handler only)
- **Contacts**: `flutter_contacts` + `url_launcher` (working)
- **Typography**: Google Fonts (Montserrat, BitcountPropSingle, Rajdhani, Pacifico)

### Unused Dependencies (4 packages)
- `firebase_core` — declared but `Firebase.initializeApp()` never called
- `firebase_auth` — never imported or used
- `webview_flutter` — never imported or used
- `latlong2` — never imported or used

### Previously Unused, Now Active
- `speech_to_text` — **Now actively used** by `VoiceAssistantService` for hands-free voice recognition

---

## 3. Architecture & File Structure

```
lib/
├── main.dart                              # Entry point → DashboardScreen
├── app.dart                               # ⚠️ DEAD CODE (unused MyApp → LoginScreen)
├── common/
│   ├── sizes.dart                         # TSizes design tokens
│   ├── text.dart                          # TTexts string constants
│   └── styles/spacing_styles.dart         # Spacing presets
└── features/
    ├── authentication/screens/
    │   ├── login/login.dart               # Login (auth faked)
    │   ├── signup/signup.dart             # Signup (auth faked)
    │   └── onboarding/onboarding.dart     # Video onboarding
    ├── dashboard/dashboard.dart           # Home screen (564 lines)
    ├── grid_screen/grid_screen.dart       # Hub: calls/music/battery/map (987 lines)
    ├── navigation/
    │   ├── maps.dart                      # Full navigation (1167 lines)
    │   └── util/background.dart           # Google Map widget + GPS tracking
    ├── profile/profile.dart               # Profile (hardcoded data)
    ├── settings/settings.dart             # Settings shell
    ├── spotify/spotify.dart               # EMPTY FILE
    ├── testing_page/tester.dart           # Dev/experimental screen (722 lines)
    └── voice_assistant/                   # 🤖 AI Voice Assistant (NEW)
        ├── voice_assistant_service.dart    # STT + TTS singleton (127 lines)
        ├── command_parser.dart             # Rule-based intent matching (102 lines)
        ├── intent_router.dart              # Command dispatch to features (91 lines)
        └── widgets/
            ├── voice_fab.dart              # Floating mic button (141 lines)
            └── voice_overlay.dart          # Full-screen listening UI (175 lines)
```

### Navigation Flow
```
DashboardScreen ↔ GridScreen ↔ ProfileScreen
                       ↓
                   MapsScreen
                       
ProfileScreen → SettingsScreen

VoiceFAB (present on GridScreen, DashboardScreen, MapsScreen)
    → VoiceOverlay (full-screen dialog)
        → CommandParser → IntentRouter → Feature execution
```

### Key Architectural Notes
- **No state management** — Pure `setState()` everywhere
- **Global mutable state** — `globalMapController` as a top-level nullable variable
- **Singleton services** — `VoiceAssistantService.instance` pattern for voice
- **No data/domain layer** — Zero models, repositories, or service abstractions (except voice)
- **Inconsistent routing** — Mix of `push()`, `pushReplacement()`, `pushNamed()`
- **Bottom nav bar duplicated** in every screen with independent state

---

## 4. Voice Assistant Architecture

The voice assistant is the most architecturally clean feature in the app, following a proper service → parser → router pattern.

### Components

#### VoiceAssistantService (`voice_assistant_service.dart`)
- **Singleton** wrapping `SpeechToText` + `FlutterTts`
- **State machine**: `idle → listening → processing → speaking → idle`
- Exposes two `ValueNotifier`s: `state` and `recognizedText`
- Auto-initializes STT/TTS on first use (lazy)
- 5-second silence timeout triggers processing automatically
- 15-second max listen duration, 3-second pause-for

#### CommandParser (`command_parser.dart`)
- **Pure function**: `String → VoiceIntent`
- Rule-based keyword/prefix matching
- Returns a `VoiceIntent` with `command` enum + `params` map
- 9 command types: navigate, call, playMusic, pauseMusic, nextTrack, previousTrack, batteryStatus, speed, unknown

#### IntentRouter (`intent_router.dart`)
- Takes a `VoiceIntent` + `BuildContext` and executes the appropriate action
- Directly calls Flutter APIs: `Navigator.push()`, `FlutterContacts`, `url_launcher`
- Provides TTS feedback for every command path

#### VoiceFAB (`widgets/voice_fab.dart`)
- Floating action button placed on key screens
- Pulse animation while listening (scale 1.0 → 1.15)
- Frosted glass effect via `BackdropFilter`
- State-aware icon: mic_none (idle), mic (listening), volume_up (speaking), spinner (processing)
- Force-resets stuck processing state on tap

#### VoiceOverlay (`widgets/voice_overlay.dart`)
- Full-screen dark overlay shown via `showGeneralDialog`
- Large pulsing mic icon with glow effect
- Real-time transcription display via `ValueListenableBuilder`
- Auto-parses and routes commands when processing begins
- Auto-dismisses when state returns to idle
- Tap-anywhere to cancel

### Supported Commands (Full Reference)

| Voice Phrase | Parsed Command | Parameters | Action |
|-------------|----------------|------------|--------|
| "Navigate to [place]" | `navigate` | `{place: String}` | Push `MapsScreen(initialDestination: place)` |
| "Take me to [place]" | `navigate` | `{place: String}` | Same as above |
| "Directions to [place]" | `navigate` | `{place: String}` | Same as above |
| "Go to [place]" | `navigate` | `{place: String}` | Same as above |
| "Call [name]" | `call` | `{name: String}` | Search contacts, dial via `url_launcher` |
| "Phone [name]" | `call` | `{name: String}` | Same as above |
| "Dial [name]" | `call` | `{name: String}` | Same as above |
| "Play music" / "Resume" | `playMusic` | — | ⚠️ Stub: speaks acknowledgment only |
| "Pause" / "Stop music" | `pauseMusic` | — | ⚠️ Stub: speaks acknowledgment only |
| "Next song" / "Skip" | `nextTrack` | — | ⚠️ Stub: speaks acknowledgment only |
| "Previous song" / "Go back" | `previousTrack` | — | ⚠️ Stub: speaks acknowledgment only |
| "Battery status" / "Battery level" | `batteryStatus` | — | ⚠️ Hardcoded: "78% / 100%" |
| "How fast" / "Current speed" | `speed` | — | ⚠️ Hardcoded: "0 km/h" |
| *(anything else)* | `unknown` | — | "Sorry, I didn't understand that command" |

### State Machine Diagram

```
          ┌───────────────────────────┐
          │                           │
          ▼                           │
       ┌──────┐   tap mic    ┌────────────┐
       │ IDLE │ ────────────▶│ LISTENING  │
       └──────┘              └────────────┘
          ▲                       │
          │                       │ silence timeout
          │                       │ or STT "notListening"
          │                       ▼
          │               ┌──────────────┐
          │               │ PROCESSING   │
          │               └──────────────┘
          │                       │
          │                       │ IntentRouter.execute()
          │                       ▼
          │               ┌──────────────┐
          └───────────────│  SPEAKING    │
            TTS complete  └──────────────┘
                                  │
                                  │ (on error)
                                  ▼
                          ┌──────────────┐
                          │    ERROR     │
                          └──────────────┘
```

---

## 5. How to Build & Run

### Prerequisites
- Flutter SDK ≥3.11.0
- Android Studio (for Android build tools)
- Physical Android device (recommended for GPS, contacts, microphone, Bluetooth)
- Google Maps API Key (with Maps SDK, Places API, Directions API, Routes API enabled)

### Setup
```bash
# Clone
git clone https://github.com/Cyberclutch146/Smart-Helmet-App.git
cd Smart-Helmet-App

# Create environment file in project root
# .env.local must contain:
# GOOGLE_MAPS_API_KEY=YOUR_KEY_HERE

# Install dependencies
flutter pub get

# Run
flutter run
```

### Critical Notes
- **`.env.local` is required** — The app force-unwraps `dotenv.env['GOOGLE_MAPS_API_KEY']!` and will crash without it
- **Asset files required** — `assets/images/helmet.png`, `assets/images/album.jpg`, `assets/images/avatar.jpg`, `assets/videos/onboarding.mp4`
- **Firebase is NOT initialized** — Despite having `firebase_core` dependency
- **`app.dart` is dead code** — `main.dart` defines its own `MyApp` that bypasses auth
- **Microphone permission** — Required for voice assistant; requested automatically on first STT init

---

## 6. Identified Flaws & Issues (35 Total)

### 🔴 Critical — Security (5)

1. **Google Maps API key hardcoded in AndroidManifest.xml** (`android/app/src/main/AndroidManifest.xml:19`)
2. **Google Maps API key hardcoded in Dart source** (`tester.dart:55`, `tester.dart:85`)
3. **Spotify Client ID hardcoded in manifest** (`AndroidManifest.xml:15`)
4. **No input validation on auth forms** (login.dart, signup.dart)
5. **Authentication completely faked** — Login accepts any input with `Future.delayed`

### 🟠 High — Architecture (7)

6. **Two conflicting `MyApp` classes** — `main.dart` and `app.dart` both define one
7. **Dead `MyHomePage` counter code** in `main.dart:51-135` — Flutter template boilerplate
8. **Global mutable `GoogleMapController?`** — Race conditions with multiple map widgets
9. **No state management** — Entire app is raw `setState()`
10. **Monolithic files** — `maps.dart` = 1167 lines, `grid_screen.dart` = 987 lines
11. **No data layer** — All API calls inline in widget `build()` or `initState()`
12. **Inconsistent navigation** — Mix of push/pushReplacement/pushNamed

### 🟡 Medium — Code Quality (9)

13. **Hardcoded contact whitelist** — Contacts filtered to "Sreyashi", "mum", etc.
14. **Hardcoded GPS coordinates** — Route locked to Gwalior, India
15. **Hardcoded profile data** — "Anuvab Das" static
16. **Hardcoded battery values** — "78%" / "100%" static (also in voice assistant)
17. **Hardcoded music metadata** — "Kanye West" static
18. **12+ `print()` debug statements** — Should use logger
19. **Massive code duplication** — `tester.dart` is a near-copy of `maps.dart`; widget classes duplicated
20. **Widget test tests wrong app** — Tests the template counter, not actual screens
21. **`_socialIcon` is a top-level function** in signup.dart

### 🟡 Medium — UX & Functionality (10)

22. **Bottom nav bar rebuilt per screen** — Independent state, no persistence
23. **Dashboard nav swipe uses `push()` not `pushReplacement()`** — Creates deep stack
24. **No loading/error states for Maps API calls** — Silent failures
25. **Back button loads network image** — Will fail offline
26. **`AudioService.init()` called every mount** — Should be once at startup
27. **Route recalc on 50m deviation with no debounce** — Could fire rapidly
28. **Firebase never initialized** — Dependency present but unused
29. **Settings tiles non-functional** — No `onTap` handlers
30. **Logout does nothing** — Just haptic feedback
31. ~~**`speech_to_text` never used**~~ — ✅ **RESOLVED**: Now used by `VoiceAssistantService`
32. **Empty `spotify.dart`** — 0 bytes

### 🔵 Low — Performance (3)

33. **Missing `const` constructors** on static widgets
34. **`AudioHandler` is empty stub** — play/pause do nothing useful
35. **`TextPainter` recreated in `build()`** for scrolling text widget

---

## 7. Voice Assistant — Future Improvements (Planned)

### Phase 1: Fix Stubs
- Wire music controls to real `AudioHandler`
- Read real phone battery via `battery_plus`
- Read GPS speed from `Geolocator`
- Add command hint chips to voice overlay
- Fix VoiceFAB rendering reliability

### Phase 2: Safety Features
- **Crash Detection & Emergency SOS** — Accelerometer-based impact detection with auto-SMS
- **Speed Limit Warning System** — Configurable limit with periodic voice warnings

### Phase 3: Convenience Features
- **Nearest Fuel/Charge Station Finder** — Google Places Nearby Search with voice navigation
- **Live Weather Alerts** — OpenWeatherMap integration with proactive warnings

### Phase 4: Advanced Features
- **Hands-Free Message Read & Reply** — Notification interception with dictation

---

## 8. Priority Action Items

1. 🔴 **Remove hardcoded API keys** — Use `.env.local` everywhere
2. 🔴 **Wire up Firebase Auth** or remove the dependency
3. 🟠 **Delete dead code** — `app.dart`, `MyHomePage`, `tester.dart`, empty `spotify.dart`
4. 🟠 **Extract shared widgets** — Bottom nav bar, animated buttons
5. 🟡 **Add state management** — Provider or Riverpod
6. ✅ **~~Implement voice assistant~~** — v1 complete, v2 in progress
7. 🟢 **Add Bluetooth connectivity** — Core value proposition

---

*Generated by deep codebase analysis. All line references are accurate to the current state of the repository.*
