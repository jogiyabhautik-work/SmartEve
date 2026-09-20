import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smarteve_mobile/core/theme/app_theme.dart';
import 'package:smarteve_mobile/core/widgets/smart_eve_bottom_nav.dart';
import 'package:smarteve_mobile/features/anchor/anchor_dashboard_screen.dart';
import 'package:smarteve_mobile/providers/anchor_provider.dart';
import 'package:smarteve_mobile/providers/notification_provider.dart';
import 'package:smarteve_mobile/providers/profile_provider.dart';

void main() {
  testWidgets('AnchorDashboardScreen renders top greeting, search, sections and bottom nav', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AnchorProvider(autoFetch: false)),
          ChangeNotifierProvider(create: (_) => NotificationProvider()),
          ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AnchorDashboardScreen(),
        ),
      ),
    );

    // Header check
    expect(find.text('SMARTEVE ANCHOR CO-PILOT'), findsOneWidget);
    expect(find.textContaining('Welcome back'), findsOneWidget);

    // Search bar check
    expect(find.byType(TextField), findsOneWidget);

    // Section 1: Sticky invitations banner check
    expect(find.text('PENDING EVENT INVITATIONS'), findsOneWidget);
    expect(find.text('Accept Invitation'), findsWidgets);

    // Section 2: Upcoming events check
    expect(find.text('UPCOMING ASSIGNMENTS'), findsOneWidget);
    expect(find.text('TechNova Live Summit 2026'), findsOneWidget);

    // Bottom Navigation dock check
    expect(find.byType(SmartEveBottomNav), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Events'), findsOneWidget);
    expect(find.text('Scripts'), findsOneWidget);
    expect(find.text('Notif'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
