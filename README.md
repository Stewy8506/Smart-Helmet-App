# 🪖 Smart Helmet App

> A next-generation smart helmet ecosystem combining **IoT, safety, and seamless connectivity** — powered by Flutter and ESP32.

---

## 🚀 Overview

The **Smart Helmet App** is a Flutter-based companion application for a custom IoT smart helmet built on ESP32/ESP32-S3 microcontrollers. Designed for motorcycle riders, it delivers real-time navigation, hands-free voice control, audio management, call handling, and safety monitoring — all optimized for use without ever touching your phone.

---

## 🧠 Key Features

### 🤖 AI Voice Assistant
The flagship feature — a fully hands-free voice command system built for rider safety.

| Command | What It Does |
|---------|--------------|
| *"Navigate to Central Park"* | Opens map, searches destination, starts turn-by-turn navigation |
| *"Take me to the airport"* | Same as navigate — supports natural phrasing |
| *"Call Sreyashi"* | Searches contacts by name, dials via phone |
| *"Play music"* / *"Pause"* | Controls music playback |
| *"Next song"* / *"Previous"* | Skips tracks forward/backward |
| *"Battery status"* | Reads phone & helmet battery levels aloud |
| *"What's my speed?"* | Reads current GPS speed in km/h |

**How it works:** Tap the floating mic button → speak your command → the assistant transcribes, parses, and executes it with voice feedback at every step.

### 🗺️ Full Google Maps Navigation
- Real-time GPS tracking with dark-themed map
- Place search with autocomplete suggestions
- Turn-by-turn navigation with voice instructions (TTS)
- Route preview with ETA, distance, and arrival time
- Auto-recalculation when deviating from route
- Zoom, rotate, and locate-me controls with glassmorphism UI

### 📞 Quick Calls
- Favorite contacts displayed on the home grid
- Tap-to-call via device phone dialer
- Voice-activated calling: *"Call [name]"*

### 🎵 Music Control
- Play/pause, skip forward/backward
- Scrolling song title with album art
- `AudioService` integration for background playback control
- Voice-activated: *"Play music"*, *"Next song"*, etc.

### 🔋 Battery Monitoring
- Phone battery percentage display
- Helmet battery status with charging indicator
- Voice-activated: *"Battery status"*

### 🏍️ Dashboard
- At-a-glance ride overview: speed, route, battery
- Swipe navigation between Dashboard ↔ Grid ↔ Profile
- Last route map preview with polyline overlay

---

## 📱 UI Design

- 🌑 **Fully dark-themed** — optimized for outdoor visibility
- ✨ **Liquid Glass effects** — iOS-inspired glassmorphism via `liquid_glass_renderer`
- 🎬 **Scroll-driven onboarding** — video-based introduction sequence
- ⚡ **Micro-animations** — pulse effects, scale transitions, haptic feedback
- 🔤 **Google Fonts** — Montserrat, Rajdhani, Pacifico for premium typography

---

## 🏗️ Tech Stack

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter (Dart SDK ^3.11.0) |
| **Maps** | Google Maps Flutter + Geolocator + Places/Directions APIs |
| **Voice** | `speech_to_text` (STT) + `flutter_tts` (TTS) |
| **Audio** | `audio_service` for background playback control |
| **Contacts** | `flutter_contacts` + `url_launcher` |
| **UI Effects** | `liquid_glass_renderer` for glassmorphism |
| **Auth** | Firebase Core/Auth (scaffolded) |
| **MCU** | ESP32 + ESP32-S3(x2) + STM32F401CCU6 (hardware side) |

---

## 📂 Project Structure

```
lib/
├── main.dart                                    # Entry point → DashboardScreen
├── common/
│   ├── sizes.dart                               # TSizes design tokens
│   ├── text.dart                                # TTexts string constants
│   └── styles/spacing_styles.dart               # Spacing presets
└── features/
    ├── authentication/screens/
    │   ├── login/login.dart                     # Login screen
    │   ├── signup/signup.dart                   # Signup screen
    │   └── onboarding/onboarding.dart           # Video onboarding
    ├── dashboard/dashboard.dart                 # Home: route preview, swipe nav
    ├── grid_screen/grid_screen.dart             # Hub: calls, music, battery, map tile
    ├── navigation/
    │   ├── maps.dart                            # Full navigation with turn-by-turn
    │   └── util/background.dart                 # Google Map widget + GPS tracking
    ├── profile/profile.dart                     # Rider profile
    ├── settings/settings.dart                   # Settings screen
    ├── spotify/spotify.dart                     # Spotify integration (planned)
    ├── testing_page/tester.dart                 # Experimental/dev screen
    └── voice_assistant/                         # 🤖 AI Voice Assistant
        ├── voice_assistant_service.dart          # STT + TTS singleton service
        ├── command_parser.dart                   # Rule-based intent matching
        ├── intent_router.dart                    # Command dispatch to app features
        └── widgets/
            ├── voice_fab.dart                    # Floating mic button with pulse
            └── voice_overlay.dart                # Full-screen listening overlay
```

---

## ⚙️ Getting Started

### Prerequisites
- Flutter SDK ≥ 3.11.0
- Android Studio (for build tools)
- Physical Android device (recommended for GPS, contacts, microphone)
- Google Maps API Key with the following APIs enabled:
  - Maps SDK for Android
  - Places API
  - Directions API
  - Routes API

### Environment Setup

Create a `.env.local` file in the project root:

```env
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
```

> ⚠️ **This file is required.** The app will crash on startup without it because it force-unwraps the API key.

### Required Assets

Ensure the following files exist in `assets/`:
- `assets/images/helmet.png` — Helmet icon
- `assets/images/album.jpg` — Music widget album art
- `assets/images/avatar.jpg` — Profile avatar
- `assets/videos/onboarding.mp4` — Onboarding video

### Installation

```bash
# Clone the repository
git clone https://github.com/Cyberclutch146/Smart-Helmet-App.git
cd Smart-Helmet-App

# Create your .env.local file (see above)

# Install dependencies
flutter pub get

# Run on connected device
flutter run
```

---

## 🧪 Development Notes

- Use a **physical device** — Bluetooth, GPS, microphone, and contacts don't work on emulators
- The voice assistant requires **microphone permission** — granted automatically on first use
- **Hot reload** (`r`) works for UI changes; use **hot restart** (`R`) after modifying services or state
- The `liquid_glass_renderer` package may show shader compilation warnings — these are non-blocking

---

## 🗺️ Navigation Flow

```
DashboardScreen ↔ GridScreen ↔ ProfileScreen
                       ↓
                   MapsScreen
                       
ProfileScreen → SettingsScreen
```

All screens include the floating `VoiceFAB` button for hands-free voice access.

---

## 🛣️ Roadmap

- [x] Dashboard with route preview
- [x] Full Google Maps navigation with turn-by-turn TTS
- [x] Contact list with tap-to-call
- [x] Music playback control UI
- [x] Battery monitoring display
- [x] AI Voice Assistant (v1)
  - [x] Navigation by voice
  - [x] Call by voice
  - [x] Music control by voice
  - [x] Battery/speed status by voice
- [ ] Crash detection & emergency SOS
- [ ] Speed limit warnings
- [ ] Nearest fuel/charging station finder
- [ ] Live weather alerts
- [ ] Hands-free message read & reply
- [ ] Bluetooth helmet connectivity (ESP32)
- [ ] Real Spotify/audio player integration
- [ ] Firebase authentication
- [ ] OTA firmware updates
- [ ] Cloud sync for ride history

---

## 🤝 Contributing

1. Fork the repo
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Commit changes (`git commit -m 'Add my feature'`)
4. Push to branch (`git push origin feature/my-feature`)
5. Open a Pull Request

---

## 📄 License

To be added.

---

## 👨‍💻 Authors

**Anuvab Das** — Hardware & App Architecture  
**Swagata** — Voice Assistant & Navigation

---

⭐ Star the repo if you like it!