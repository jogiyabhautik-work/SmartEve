import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/notification_model.dart';
import '../../../providers/notification_provider.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  late NotificationPreferences _prefs;

  @override
  void initState() {
    super.initState();
    final provider = context.read<NotificationProvider>();
    _prefs = provider.preferences;
  }

  void _update(NotificationPreferences newPrefs) {
    setState(() => _prefs = newPrefs);
    context.read<NotificationProvider>().updatePreferences(newPrefs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('Notification Settings'),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('GLOBAL CHANNELS'),
          _buildCard([
            _buildSwitchTile(
              title: 'Push Notifications',
              subtitle: 'Mobile device popups & banners',
              icon: Icons.notifications_active_rounded,
              iconColor: AppTheme.primaryBlue,
              value: _prefs.pushEnabled,
              onChanged: (v) => _update(_prefs.copyWith(pushEnabled: v)),
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              title: 'In-App Notifications',
              subtitle: 'Alerts & badges inside SmartEve',
              icon: Icons.system_security_update_warning_rounded,
              iconColor: AppTheme.primaryPurple,
              value: _prefs.inAppEnabled,
              onChanged: (v) => _update(_prefs.copyWith(inAppEnabled: v)),
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              title: 'Email Digest',
              subtitle: 'Daily summary emails for stage updates',
              icon: Icons.mark_email_read_rounded,
              iconColor: AppTheme.liveGreen,
              value: _prefs.emailEnabled,
              onChanged: (v) => _update(_prefs.copyWith(emailEnabled: v)),
            ),
          ]),

          const SizedBox(height: 20),
          _buildSectionHeader('SOUND & VIBRATION'),
          _buildCard([
            _buildSwitchTile(
              title: 'Notification Sound',
              subtitle: 'Play gentle bell sound for new alerts',
              icon: Icons.volume_up_rounded,
              iconColor: AppTheme.warningAmber,
              value: _prefs.soundEnabled,
              onChanged: (v) => _update(_prefs.copyWith(soundEnabled: v)),
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              title: 'Haptic Vibration',
              subtitle: 'Vibrate device on high priority alerts',
              icon: Icons.vibration_rounded,
              iconColor: AppTheme.cyan,
              value: _prefs.vibrationEnabled,
              onChanged: (v) => _update(_prefs.copyWith(vibrationEnabled: v)),
            ),
          ]),

          const SizedBox(height: 20),
          _buildSectionHeader('NOTIFICATION CATEGORIES'),
          _buildCard([
            _buildSwitchTile(
              title: 'Anchor Invitations',
              subtitle: 'Stage anchor requests & acceptances',
              icon: Icons.mic_rounded,
              iconColor: AppTheme.primaryPurple,
              value: _prefs.invitationsEnabled,
              onChanged: (v) => _update(_prefs.copyWith(invitationsEnabled: v)),
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              title: 'Direct Messages & Chat',
              subtitle: 'Messages between Anchor & Organizer',
              icon: Icons.chat_rounded,
              iconColor: AppTheme.primaryBlue,
              value: _prefs.messagesEnabled,
              onChanged: (v) => _update(_prefs.copyWith(messagesEnabled: v)),
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              title: 'Script & Agenda Updates',
              subtitle: 'AI script revisions & time slot shifts',
              icon: Icons.description_rounded,
              iconColor: AppTheme.liveGreen,
              value: _prefs.updatesEnabled,
              onChanged: (v) => _update(_prefs.copyWith(updatesEnabled: v)),
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              title: 'Urgent Stage Alerts & Delays',
              subtitle: 'Schedule delay reports & SOS requests',
              icon: Icons.warning_amber_rounded,
              iconColor: AppTheme.error,
              value: _prefs.alertsEnabled,
              onChanged: (v) => _update(_prefs.copyWith(alertsEnabled: v)),
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              title: 'Event Reminders',
              subtitle: '15-min & 1-hour pre-event countdowns',
              icon: Icons.alarm_rounded,
              iconColor: AppTheme.warningAmber,
              value: _prefs.remindersEnabled,
              onChanged: (v) => _update(_prefs.copyWith(remindersEnabled: v)),
            ),
          ]),

          const SizedBox(height: 20),
          _buildSectionHeader('QUIET HOURS'),
          _buildCard([
            _buildSwitchTile(
              title: 'Enable Quiet Hours',
              subtitle: 'Only urgent alerts bypass quiet hours',
              icon: Icons.bedtime_rounded,
              iconColor: AppTheme.primaryPurple,
              value: _prefs.quietHoursEnabled,
              onChanged: (v) => _update(_prefs.copyWith(quietHoursEnabled: v)),
            ),
            if (_prefs.quietHoursEnabled) ...[
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.access_time_rounded, color: AppTheme.textSecondary),
                title: const Text('Quiet Hours Window'),
                subtitle: Text('${_prefs.quietHoursStart} – ${_prefs.quietHoursEnd} (${_prefs.quietHoursTimezone})'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  final start = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 22, minute: 0),
                  );
                  if (start != null && mounted) {
                    final end = await showTimePicker(
                      context: context,
                      initialTime: const TimeOfDay(hour: 7, minute: 0),
                    );
                    if (end != null && mounted) {
                      final startStr = '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}:00';
                      final endStr = '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}:00';
                      _update(_prefs.copyWith(
                        quietHoursStart: startStr,
                        quietHoursEnd: endStr,
                      ));
                    }
                  }
                },
              ),
            ],
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
      ),
      value: value,
      activeColor: AppTheme.primaryBlue,
      onChanged: onChanged,
    );
  }
}
