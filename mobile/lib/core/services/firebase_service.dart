import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool _isInitialized = false;
  String? _fcmToken;

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

        // Listen for foreground notifications
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint("📢 Foreground FCM Alert: ${message.notification?.title} - ${message.notification?.body}");
          _notificationStreamController.add(message);
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
