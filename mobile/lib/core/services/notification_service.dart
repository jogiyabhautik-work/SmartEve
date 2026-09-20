import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../network/api_client.dart';
import '../../features/events/event_details_screen.dart';
import '../../features/scripts/scripts_library_screen.dart';
import '../../features/dashboard/stagepilot_dashboard_screen.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final ApiClient _apiClient = ApiClient();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> registerDeviceToken(String userId, String deviceId) async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _apiClient.post('/notifications/tokens', {
          'userId': userId,
          'deviceId': deviceId,
          'deviceType': 'android',
          'fcmToken': token,
        });
        debugPrint("📱 Registered FCM token with backend for user $userId");
      }
    } catch (e) {
      debugPrint("ℹ️ FCM Token Registration skipped or mock mode: $e");
    }
  }

  void handleActionUrl(BuildContext context, String? actionUrl) {
    if (actionUrl == null || actionUrl.trim().isEmpty) return;

    final url = actionUrl.trim();
    debugPrint("🔗 Handling deep link: $url");

    if (url.contains('/details') || url.contains('/event')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const EventDetailsScreen()),
      );
    } else if (url.contains('/scripts')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ScriptsLibraryScreen()),
      );
    } else if (url.contains('/live') || url.contains('/checklist')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StagePilotDashboardScreen()),
      );
    }
  }
}
