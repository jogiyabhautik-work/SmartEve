import 'package:flutter/foundation.dart';

class AppConstants {
  static const String appName = 'SmartEve';
  static const String appTagline = "Your Event's Co-Pilot";

  // Backend API URL:
  // - Android emulator: 10.0.2.2:4000
  // - iOS simulator / Web / Desktop: localhost:4000
  // - Physical Device: Change to your local development machine IP (e.g. 192.168.1.50:4000)
  static String get apiBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:4000/api';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:4000/api';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      default:
        return 'http://localhost:4000/api';
    }
  }

  static const String demoJoinCode = 'TN26';
  static const String demoEventId = 'technova-2026';
}
