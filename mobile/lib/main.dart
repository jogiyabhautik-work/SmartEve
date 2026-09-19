import 'package:flutter/material.dart';
import 'app.dart';
import 'core/services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase (Auth, Push Notifications, Analytics)
  await FirebaseService().initialize();
  runApp(const SmartEveApp());
}
