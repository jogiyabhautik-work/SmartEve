import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/event_provider.dart';
import '../../core/services/firebase_service.dart';
import '../dashboard/stagepilot_dashboard_screen.dart';
import '../anchor/anchor_teleprompter_screen.dart';
import '../stage_display/stage_display_screen.dart';
import '../organizer/screens/organizer_dashboard_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../attendee/attendee_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final TextEditingController _codeController = TextEditingController();
  StreamSubscription<RemoteMessage>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EventProvider>().fetchOrganizerEvents();
    });

    _notificationSubscription = FirebaseService().onNotificationReceived.listen((message) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔔 ${message.notification?.title ?? 'New Notification'}: ${message.notification?.body ?? ''}'),
            backgroundColor: AppTheme.liveGreen,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // App Brand Header
              Center(
                child: Image.asset(
                  'assets/trans_icon.png',
                  width: 70,
                  height: 70,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.sensors_rounded,
                    size: 48,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'SMARTEVE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                AppConstants.appTagline,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 36),

              // Join Code Input Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'EVENT JOIN CODE',
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: AppTheme.primaryBlue,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppTheme.surfaceLight,
                        hintText: 'e.g. TN26',
                        hintStyle: const TextStyle(color: AppTheme.textMuted),
                        prefixIcon: const Icon(Icons.qr_code_rounded, color: AppTheme.primaryBlue),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              const Text(
                'SELECT YOUR ROLE',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 14),

              // Role 0: Attendee Companion App
              _buildRoleCard(
                icon: Icons.smartphone_rounded,
                title: 'Attendee Companion App',
                subtitle: 'Real-time stage timeline, speaker roster & live audience Q&A',
                badgeText: 'ATTENDEE',
                badgeColor: AppTheme.cyan,
                onTap: () => _navigateTo(const AttendeeScreen()),
              ),
              const SizedBox(height: 14),

              // Role 1: Organizer Portal
              _buildRoleCard(
                icon: Icons.dashboard_customize_rounded,
                title: 'Organizer Portal',
                subtitle: 'Manage events, create new events, speaker roster & publish to anchors',
                badgeText: 'ORGANIZER',
                badgeColor: AppTheme.primaryBlue,
                onTap: () => _navigateTo(const OrganizerDashboardScreen()),
              ),
              const SizedBox(height: 14),

              // Role 2: StagePilot AI Suite
              _buildRoleCard(
                icon: Icons.tune_rounded,
                title: 'Control Room Suite',
                subtitle: 'Live session timers, schedule reflow engine & AI assistant',
                badgeText: 'CONTROL ROOM',
                badgeColor: AppTheme.primaryPurple,
                onTap: () => _navigateTo(const StagePilotDashboardScreen()),
              ),
              const SizedBox(height: 14),

              // Role 3: Anchor Teleprompter
              _buildRoleCard(
                icon: Icons.mic_external_on_rounded,
                title: 'Anchor Teleprompter',
                subtitle: 'Speaker intros, fail-safe AI scripts & live read-aloud TTS',
                badgeText: 'STAGE HOST',
                badgeColor: AppTheme.liveGreen,
                onTap: () => _navigateTo(const AnchorTeleprompterScreen()),
              ),
              const SizedBox(height: 14),

              // Role 4: Admin Hub
              _buildRoleCard(
                icon: Icons.admin_panel_settings_rounded,
                title: 'Admin Control Center',
                subtitle: 'Platform oversight, user management & AI model fallback config',
                badgeText: 'ADMIN',
                badgeColor: AppTheme.primaryPurple,
                onTap: () => _navigateTo(const AdminDashboardScreen()),
              ),
              const SizedBox(height: 14),

              // Role 5: Public Stage Display
              _buildRoleCard(
                icon: Icons.cast_connected_rounded,
                title: 'Stage Projector Display',
                subtitle: 'High-contrast countdown timer and speaker billboard',
                badgeText: 'DISPLAY',
                badgeColor: AppTheme.warningAmber,
                onTap: () => _navigateTo(const StageDisplayScreen()),
              ),
              const SizedBox(height: 32),

              // Backend Status Tag
              Consumer<EventProvider>(
                builder: (context, provider, _) {
                  final hasEvent = provider.event != null;
                  return Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: hasEvent ? AppTheme.liveGreen.withValues(alpha: 0.12) : AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: hasEvent ? AppTheme.liveGreen.withValues(alpha: 0.4) : AppTheme.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: hasEvent ? AppTheme.liveGreen : AppTheme.warningAmber,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            hasEvent
                                ? 'Connected: ${provider.event!.name}'
                                : 'Connecting to .ts backend...',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: hasEvent ? AppTheme.liveGreen : AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Notification Test Button
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    await FirebaseService().showTestNotification();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Test notification sent! Check your system tray.'),
                          backgroundColor: AppTheme.cyan,
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.notifications_active_rounded, color: AppTheme.cyan),
                  label: const Text(
                    'Trigger Test Notification',
                    style: TextStyle(color: AppTheme.cyan, fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    backgroundColor: AppTheme.cyan.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: badgeColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
