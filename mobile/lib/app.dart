import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/event_provider.dart';
import 'providers/anchor_provider.dart';
import 'providers/checklist_provider.dart';
import 'providers/scripts_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/notification_provider.dart';
import 'features/ai_assistant/providers/ai_chat_provider.dart';
import 'features/auth/splash_screen.dart';

class SmartEveApp extends StatelessWidget {
  const SmartEveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => AnchorProvider()),
        ChangeNotifierProvider(create: (_) => ChecklistProvider()),
        ChangeNotifierProvider(create: (_) => ScriptsProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()..loadProfile()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()..load()),
        ChangeNotifierProvider(create: (_) => AiChatProvider()),
      ],
      child: MaterialApp(
        title: 'SmartEve',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
