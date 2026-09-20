import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool _isInitialized = false;
  String? _fcmToken;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool get isInitialized => _isInitialized;
  String? get fcmToken => _fcmToken;

  final StreamController<RemoteMessage> _notificationStreamController =
      StreamController<RemoteMessage>.broadcast();

  Stream<RemoteMessage> get onNotificationReceived => _notificationStreamController.stream;

  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      _isInitialized = true;
      debugPrint("🔥 Firebase initialized successfully");

      await _setupAuth();
      await _setupFcm();
      await _setupLocalNotifications();
    } catch (e) {
      debugPrint("ℹ️ Firebase initialization skipped or mock mode: $e");
    }
  }

  Future<void> _setupAuth() async {
    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        // Sign in anonymously for zero-friction stage anchor access
        await auth.signInAnonymously();
        debugPrint("🔑 Firebase Auth: Signed in anonymously (${auth.currentUser?.uid})");
      }
    } catch (e) {
      debugPrint("Firebase Auth error: $e");
    }
  }

  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@drawable/trans_icon');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    
    await _localNotifications.initialize(initSettings);
  }

  Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'test_channel_id',
      'Test Notifications',
      channelDescription: 'Channel for testing notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const platformDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);
    
    await _localNotifications.show(
      Random().nextInt(100000),
      'SmartEve Test Notification',
      'This is a test message triggered by your button!',
      platformDetails,
    );
  }

  Future<void> showForegroundNotification(
      {required String title, required String body}) async {
    const androidDetails = AndroidNotificationDetails(
      'smarteve_alerts',
      'SmartEve Alerts',
      channelDescription: 'Event updates, messages and urgent alerts',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const platformDetails =
        NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _localNotifications.show(
      Random().nextInt(100000),
      title,
      body,
      platformDetails,
    );
  }

  Future<void> _setupFcm() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        _fcmToken = await messaging.getToken();
        debugPrint("📱 FCM Token: $_fcmToken");

        // Listen for foreground notifications: banner + sound + vibration
        // (enabled by default; toggled in profile notification settings)
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint("📢 Foreground FCM Alert: ${message.notification?.title} - ${message.notification?.body}");
          _notificationStreamController.add(message);
          showForegroundNotification(
            title: message.notification?.title ?? 'SmartEve',
            body: message.notification?.body ?? 'You have a new update',
          );
        });
      }
    } catch (e) {
      debugPrint("FCM setup error: $e");
    }
  }

  Future<String?> getIdToken() async {
    if (!_isInitialized) return null;
    try {
      return await FirebaseAuth.instance.currentUser?.getIdToken();
    } catch (_) {
      return null;
    }
  }

  Future<void> subscribeToEvent(String eventId) async {
    if (!_isInitialized) return;
    try {
      await FirebaseMessaging.instance.subscribeToTopic('event-$eventId');
      debugPrint("📡 Subscribed to FCM topic: event-$eventId");
    } catch (e) {
      debugPrint("Error subscribing to topic: $e");
    }
  }
}
