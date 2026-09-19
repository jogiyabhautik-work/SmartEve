# SmartEve Mobile App (Flutter)

A mission-critical mobile application for **Stage Anchors**, **Live Event Organizers**, and **Stage Display Projectors**.

---

## 📌 Project Overview
SmartEve Mobile is built using Flutter (Dart) and designed to give stage managers, anchors, and event organizers real-time control over live event schedules, AI-assisted stage scripts, and countdown timers.

---

## 🛠️ Tech Stack & Dependencies
- **Framework**: Flutter (Dart SDK `>=3.2.0 <4.0.0`)
- **State Management**: Provider (`provider: ^6.1.2`)
- **Theme**: Custom `AppTheme.lightTheme` with slate light tokens (`#F8FAFC`, `#FFFFFF`, `#2563EB`)
- **Authentication**: Firebase Auth & Neon DB fallback resilience
- **Notifications**: Firebase Cloud Messaging (FCM) & `flutter_local_notifications`
- **Voice Synthesis**: `flutter_tts` for script read-aloud
- **Image CDN**: `cached_network_image` & Cloudinary upload client
- **Icons**: `flutter_launcher_icons` (`smartEVE-icon.png` launcher & `trans_icon.png` notification icon)

---

## 📈 Recent Improvements & Progress
- **UI Regeneration (Light Theme)**: Converted all screens to a cohesive, modern Light Theme (`AppTheme.lightTheme`).
- **Forgot Password**: Implemented interactive reset password modal flow in `LoginScreen` with email validation.
- **Native Launcher & Notification Icons**: Set `smartEVE-icon.png` as launcher icon and `trans_icon.png` for Android notifications, Splash screen, and Login screen header.
- **Multi-Step Registration**: 6-step registration flow for Organizers and Anchors.
- **Teleprompter & AI Assistant**: Integrated quad-tier AI script generation and TTS playback.

---

## 🚀 Setup & Running

```bash
# Get dependencies
flutter pub get

# Generate launcher icons
dart run flutter_launcher_icons

# Run mobile application
flutter run
```
