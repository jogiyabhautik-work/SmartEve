import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:smarteve_mobile/core/theme/app_theme.dart';
import 'package:smarteve_mobile/features/profile/profile_settings_screen.dart';
import 'package:smarteve_mobile/features/profile/widgets/profile_header_card.dart';
import 'package:smarteve_mobile/features/profile/widgets/profile_stats_section.dart';
import 'package:smarteve_mobile/features/profile/widgets/settings_tab_view.dart';
import 'package:smarteve_mobile/features/profile/widgets/social_links_section.dart';
import 'package:smarteve_mobile/providers/profile_provider.dart';

void main() {
  testWidgets('ProfileSettingsScreen renders header, stats, social links, tabs, and action buttons', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: ProfileSettingsScreen(isEmbedded: true),
          ),
        ),
      ),
    );
    await tester.pump();

    // Verify Profile Header Card
    expect(find.byType(ProfileHeaderCard), findsOneWidget);
    expect(find.text('Jordan Hayes'), findsOneWidget);
    expect(find.text('ABOUT & BIO'), findsOneWidget);
    expect(find.text('LANGUAGES'), findsOneWidget);
    expect(find.text('SPECIALIZATIONS'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Hackathons'), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);

    // Verify Stats Section
    expect(find.byType(ProfileStatsSection), findsOneWidget);
    expect(find.text('STAGE PERFORMANCE METRICS'), findsOneWidget);
    expect(find.text('Events Anchored'), findsOneWidget);
    expect(find.text('24'), findsOneWidget);
    expect(find.text('96h'), findsOneWidget);

    // Verify Social Links Section
    expect(find.byType(SocialLinksSection), findsOneWidget);
    expect(find.text('PROFESSIONAL & SOCIAL LINKS'), findsOneWidget);
    expect(find.text('LinkedIn'), findsOneWidget);
    expect(find.text('Twitter / X'), findsOneWidget);
    expect(find.text('Portfolio'), findsOneWidget);
    expect(find.text('YouTube'), findsOneWidget);

    // Verify Settings Tabs
    expect(find.byType(SettingsTabView), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Preferences'), findsOneWidget);
    expect(find.text('Privacy & Security'), findsOneWidget);
    expect(find.text('Help & Support'), findsOneWidget);

    // Verify Action Buttons
    expect(find.text('Log Out of SmartEve'), findsOneWidget);
  });
}
