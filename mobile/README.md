# SmartEve Mobile App (Flutter)

A mission-critical mobile application for **Stage Anchors**, **Live Event Organizers**, and **Stage Displays**.

---

## 🚀 Key Features
- **Control Room Dashboard**: Live session countdown, session switcher, and 1-tap `+15m` / `+5m` / `-5m` delay triggers.
- **Anchor Teleprompter**: Speaker intro cards, stage talking points, and AI-generated announcement scripts with offline fallback.
- **One-Touch Voice Synthesis (TTS)**: Built-in speech synthesis allowing anchors to rehearse or audition stage scripts aloud.
- **Stage Display Mode**: Oversized, high-contrast countdown timer and speaker billboard for projector displays.
- **Deterministic Reflow Integration**: Connects with the Node.js / TypeScript backend engine to sync schedule changes in real time.

---

## 🛠️ Setup & Running

### 1. Prerequisites
- Flutter SDK (3.2.0 or later)
- Android Studio / Xcode (or Chrome for Flutter Web)

### 2. Configure Backend Connection
By default, the app is configured to connect to:
- **Android Emulator**: `http://10.0.2.2:4000/api`
- **iOS Simulator / Desktop / Web**: `http://localhost:4000/api`
- **Physical Device**: Replace with your local machine's IP (e.g., `http://192.168.1.X:4000/api`) in `lib/core/constants/app_constants.dart`.

### 3. Run the App
```bash
# Get dependencies
flutter pub get

# Run on connected device or emulator
flutter run
```
