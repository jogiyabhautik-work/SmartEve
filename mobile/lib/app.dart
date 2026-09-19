import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/event_provider.dart';
import 'features/auth/role_selection_screen.dart';

class SmartEveApp extends StatelessWidget {
  const SmartEveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EventProvider()),
      ],
      child: MaterialApp(
        title: 'SmartEve',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const RoleSelectionScreen(),
      ),
    );
  }
}
