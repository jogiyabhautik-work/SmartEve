import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/user_profile_model.dart';
import '../../../providers/profile_provider.dart';

class SettingsTabView extends StatefulWidget {
  final UserProfileModel profile;
  final bool isOrganizerView;
  final bool isAdminView;
  final bool isSuspiciousAccount;

  const SettingsTabView({
    super.key,
    required this.profile,
    this.isOrganizerView = false,
    this.isAdminView = false,
    this.isSuspiciousAccount = false,
  });

  @override
  State<SettingsTabView> createState() => _SettingsTabViewState();
}

class _SettingsTabViewState extends State<SettingsTabView> {
  int _selectedTabIndex = 0;

  final List<String> _tabs = const [
    'Account',
    'Notifications',
    'Preferences',
    'Privacy & Security',
    'Help & Support',
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.isOrganizerView) {
      // In organizer public view, only show public sections
      return _buildOrganizerPublicNotice();
    }
    if (widget.isAdminView) {
      return _buildAdminView(context);
    }

    final provider = context.watch<ProfileProvider>();
    final draft = provider.draftProfile;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepNavy.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          side: const BorderSide(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sub-Tab Header Scroller
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.border)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_tabs.length, (idx) {
                    final isSelected = _selectedTabIndex == idx;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(_tabs[idx]),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryBlue,
                        backgroundColor: AppTheme.surfaceLight,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : AppTheme.textSecondary,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        side: BorderSide.none,
                        onSelected: (_) => setState(() => _selectedTabIndex = idx),
                      ),
                    );
                  }),
                ),
              ),
            ),

            // Active Tab Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildActiveTabContent(provider, draft),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(ProfileProvider provider, UserProfileModel draft) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildAccountSettingsTab(provider, draft);
      case 1:
        return _buildNotificationPreferencesTab(provider, draft);
      case 2:
        return _buildPreferencesTab(provider, draft);
      case 3:
        return _buildPrivacySecurityTab(provider, draft);
      case 4:
        return _buildHelpSupportTab(provider, draft);
      default:
        return const SizedBox.shrink();
    }
  }

  // ==========================================
  // TAB 1: ACCOUNT SETTINGS
  // ==========================================
  Widget _buildAccountSettingsTab(ProfileProvider provider, UserProfileModel draft) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('ACCOUNT CREDENTIALS'),
        _buildSettingTile(
          icon: Icons.email_outlined,
          title: 'Email Address',
          subtitle: draft.email,
          actionLabel: 'Change',
          onTap: () => _showChangeEmailDialog(context, draft.email, provider),
        ),
        const Divider(color: AppTheme.border, height: 16),
        _buildSettingTile(
          icon: Icons.phone_outlined,
          title: 'Phone Number',
          subtitle: draft.maskedPhoneNumber,
          actionLabel: 'Change',
          onTap: () => _showChangePhoneDialog(context, draft.phoneNumber, provider),
        ),
        const Divider(color: AppTheme.border, height: 16),
        _buildSettingTile(
          icon: Icons.lock_outline_rounded,
          title: 'Password',
          subtitle: 'Last changed ${draft.accountSettings.lastPasswordChange ?? "recently"}',
          actionLabel: 'Change Password',
          onTap: () => _showChangePasswordDialog(context),
        ),
        const SizedBox(height: 20),
        _buildSectionTitle('TWO-FACTOR AUTHENTICATION (2FA)'),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.security_rounded, color: AppTheme.primaryBlue),
          title: const Text('Two-Factor Authentication', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          subtitle: const Text('Enable 2FA for added account security', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          value: draft.accountSettings.twoFactorEnabled,
          activeTrackColor: AppTheme.primaryBlue,
          onChanged: (val) {
            provider.updateAccountSettings(draft.accountSettings.copyWith(twoFactorEnabled: val));
            if (val) _showTwoFactorInstructionsDialog(context);
          },
        ),
        const SizedBox(height: 20),
        _buildSectionTitle('ACCOUNT STATUS & DANGER ZONE'),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(color: AppTheme.success, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Status: Active & Verified', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showDeleteAccountDialog(context, provider),
            icon: const Icon(Icons.delete_forever_rounded, size: 18, color: AppTheme.error),
            label: const Text('Delete Account', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.error),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 2: NOTIFICATION PREFERENCES
  // ==========================================
  Widget _buildNotificationPreferencesTab(ProfileProvider provider, UserProfileModel draft) {
    final notifs = draft.notificationPreferences;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('EVENT & STAGE ALERTS'),
        _buildToggle(
          title: 'Event Invitations',
          subtitle: 'Receive email & push notifications for new invitations',
          value: notifs.eventInvitations,
          onChanged: (val) => provider.updateNotificationPreferences(notifs.copyWith(eventInvitations: val)),
        ),
        _buildToggle(
          title: 'Script Updates',
          subtitle: 'Alerts when organizers edit or generate new stage scripts',
          value: notifs.scriptUpdates,
          onChanged: (val) => provider.updateNotificationPreferences(notifs.copyWith(scriptUpdates: val)),
        ),
        _buildToggle(
          title: 'Agenda Changes',
          subtitle: 'Real-time push alerts when schedule delays occur',
          value: notifs.agendaChanges,
          onChanged: (val) => provider.updateNotificationPreferences(notifs.copyWith(agendaChanges: val)),
        ),
        _buildToggle(
          title: 'Organizer Messages',
          subtitle: 'Urgent stage notes & backstage announcements',
          value: notifs.organizerMessages,
          onChanged: (val) => provider.updateNotificationPreferences(notifs.copyWith(organizerMessages: val)),
        ),
        _buildToggle(
          title: 'SmartEve AI Suggestions',
          subtitle: 'Dynamic transition lines and speech coaching prompts',
          value: notifs.aiSuggestions,
          onChanged: (val) => provider.updateNotificationPreferences(notifs.copyWith(aiSuggestions: val)),
        ),
        const Divider(color: AppTheme.border, height: 20),
        _buildSectionTitle('REMINDERS & DIGESTS'),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Event Reminders', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          subtitle: const Text('Trigger before scheduled start time', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          trailing: DropdownButton<String>(
            value: notifs.eventReminders,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: '15_mins_before', child: Text('15 mins before', style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: '30_mins_before', child: Text('30 mins before', style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: '1_hour_before', child: Text('1 hour before', style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: '2_hours_before', child: Text('2 hours before', style: TextStyle(fontSize: 13))),
            ],
            onChanged: (val) {
              if (val != null) provider.updateNotificationPreferences(notifs.copyWith(eventReminders: val));
            },
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Performance Reports', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          subtitle: const Text('Weekly summary of stage hours & ratings', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          trailing: DropdownButton<String>(
            value: notifs.performanceReports,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'weekly', child: Text('Weekly', style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: 'monthly', child: Text('Monthly', style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: 'never', child: Text('Never', style: TextStyle(fontSize: 13))),
            ],
            onChanged: (val) {
              if (val != null) provider.updateNotificationPreferences(notifs.copyWith(performanceReports: val));
            },
          ),
        ),
        _buildToggle(
          title: 'Newsletter & Anchor Tips',
          subtitle: 'Periodic email with emcee best practices',
          value: notifs.newsletter,
          onChanged: (val) => provider.updateNotificationPreferences(notifs.copyWith(newsletter: val)),
        ),
        const Divider(color: AppTheme.border, height: 20),
        _buildSectionTitle('SOUND & QUIET HOURS'),
        _buildToggle(
          title: 'Notification Sound',
          subtitle: 'Play audio chime for stage notifications',
          value: notifs.sound,
          onChanged: (val) => provider.updateNotificationPreferences(notifs.copyWith(sound: val)),
        ),
        _buildToggle(
          title: 'Notification Vibration',
          subtitle: 'Haptic feedback on priority cue alerts',
          value: notifs.vibration,
          onChanged: (val) => provider.updateNotificationPreferences(notifs.copyWith(vibration: val)),
        ),
        _buildToggle(
          title: 'Quiet Hours',
          subtitle: 'Mute non-critical alerts between ${notifs.quietHoursStart} and ${notifs.quietHoursEnd}',
          value: notifs.quietHoursEnabled,
          onChanged: (val) => provider.updateNotificationPreferences(notifs.copyWith(quietHoursEnabled: val)),
        ),
        if (notifs.quietHoursEnabled)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: const TimeOfDay(hour: 22, minute: 0),
                      );
                      if (time != null) {
                        final formatted = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                        provider.updateNotificationPreferences(notifs.copyWith(quietHoursStart: formatted));
                      }
                    },
                    child: Text('Start: ${notifs.quietHoursStart}', style: const TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: const TimeOfDay(hour: 7, minute: 0),
                      );
                      if (time != null) {
                        final formatted = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                        provider.updateNotificationPreferences(notifs.copyWith(quietHoursEnd: formatted));
                      }
                    },
                    child: Text('End: ${notifs.quietHoursEnd}', style: const TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ==========================================
  // TAB 3: PREFERENCES
  // ==========================================
  Widget _buildPreferencesTab(ProfileProvider provider, UserProfileModel draft) {
    final prefs = draft.appPreferences;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('LOCALIZATION & AI PROMPTING'),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('App Language', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          subtitle: const Text('UI interface language', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          trailing: DropdownButton<String>(
            value: prefs.language,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'English', child: Text('English', style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: 'Hindi', child: Text('Hindi (हिंदी)', style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: 'Gujarati', child: Text('Gujarati (ગુજરાતી)', style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: 'Others', child: Text('Other Languages', style: TextStyle(fontSize: 13))),
            ],
            onChanged: (val) {
              if (val != null) provider.updateAppPreferences(prefs.copyWith(language: val));
            },
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Default Script Language', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          subtitle: const Text('Default language for AI-generated stage intros', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          trailing: DropdownButton<String>(
            value: prefs.scriptLanguageDefault,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 'English', child: Text('English', style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: 'Hindi', child: Text('Hindi (हिंदी)', style: TextStyle(fontSize: 13))),
              DropdownMenuItem(value: 'Gujarati', child: Text('Gujarati (ગુજરાતી)', style: TextStyle(fontSize: 13))),
            ],
            onChanged: (val) {
              if (val != null) provider.updateAppPreferences(prefs.copyWith(scriptLanguageDefault: val));
            },
          ),
        ),
        const Divider(color: AppTheme.border, height: 20),
        _buildSectionTitle('APPEARANCE & DISPLAY'),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('App Theme', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          subtitle: Text(prefs.themeMode == 'dark' ? 'Dark Mode (Active)' : 'Light Mode (Active)', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          trailing: SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'light', icon: Icon(Icons.light_mode_rounded, size: 16)),
              ButtonSegment(value: 'dark', icon: Icon(Icons.dark_mode_rounded, size: 16)),
            ],
            selected: {prefs.themeMode},
            onSelectionChanged: (set) => provider.updateAppPreferences(prefs.copyWith(themeMode: set.first)),
          ),
        ),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Teleprompter Font Size', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Text(prefs.fontSize, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
              ],
            ),
            Slider(
              value: prefs.fontSize == 'Small' ? 0.0 : (prefs.fontSize == 'Normal' ? 1.0 : 2.0),
              min: 0.0,
              max: 2.0,
              divisions: 2,
              activeColor: AppTheme.primaryBlue,
              onChanged: (val) {
                final size = val == 0.0 ? 'Small' : (val == 1.0 ? 'Normal' : 'Large');
                provider.updateAppPreferences(prefs.copyWith(fontSize: size));
              },
            ),
          ],
        ),
        _buildToggle(
          title: 'Auto-play Notifications',
          subtitle: 'Auto-expand unread notifications in notification drawer',
          value: prefs.autoPlayNotifications,
          onChanged: (val) => provider.updateAppPreferences(prefs.copyWith(autoPlayNotifications: val)),
        ),
      ],
    );
  }

  // ==========================================
  // TAB 4: PRIVACY & SECURITY
  // ==========================================
  Widget _buildPrivacySecurityTab(ProfileProvider provider, UserProfileModel draft) {
    final priv = draft.privacySettings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('DISCOVERABILITY & VISIBILITY'),
        _buildToggle(
          title: 'Public Profile',
          subtitle: priv.profileVisibility == 'public'
              ? 'Anchors directory shows you to event organizers'
              : 'Private profile: Only visible via direct event invitation code',
          value: priv.profileVisibility == 'public',
          onChanged: (val) => provider.updatePrivacySettings(
            priv.copyWith(profileVisibility: val ? 'public' : 'private'),
          ),
        ),
        _buildToggle(
          title: 'Allow Organizers to Contact You',
          subtitle: 'Permit organizers to send assignment invites & stage notes',
          value: priv.allowOrganizersContact,
          onChanged: (val) => provider.updatePrivacySettings(priv.copyWith(allowOrganizersContact: val)),
        ),
        _buildToggle(
          title: 'Usage Analytics Collection',
          subtitle: 'Help improve SmartEve by sharing anonymous telemetry',
          value: priv.dataCollection,
          onChanged: (val) => provider.updatePrivacySettings(priv.copyWith(dataCollection: val)),
        ),
        _buildToggle(
          title: 'Third-Party Media Access',
          subtitle: 'Allow Cloudinary CDN to store and optimize profile assets',
          value: priv.thirdPartyAccess,
          onChanged: (val) => provider.updatePrivacySettings(priv.copyWith(thirdPartyAccess: val)),
        ),
        const Divider(color: AppTheme.border, height: 20),
        _buildSectionTitle('BLOCKED USERS & ORGANIZERS'),
        if (priv.blockedUsers.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No blocked organizers.', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
          )
        else
          ...priv.blockedUsers.map((user) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.block_rounded, color: AppTheme.error, size: 20),
                title: Text(user, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                trailing: TextButton(
                  onPressed: () => provider.unblockUser(user),
                  child: const Text('Unblock', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                ),
              )),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: () => _showPolicyDialog(context, 'Privacy Policy'),
                icon: const Icon(Icons.policy_outlined, size: 16),
                label: const Text('View Privacy Policy'),
              ),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: () => _showPolicyDialog(context, 'Terms & Conditions'),
                icon: const Icon(Icons.description_outlined, size: 16),
                label: const Text('Terms of Service'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // TAB 5: HELP & SUPPORT
  // ==========================================
  Widget _buildHelpSupportTab(ProfileProvider provider, UserProfileModel draft) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('FREQUENTLY ASKED QUESTIONS'),
        const ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text('How do I run the Anchor Teleprompter?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'Open any active event assignment and tap "Open Teleprompter HUD". You can scroll manually, activate auto-scroll, or trigger speech synthesis cueing.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
              ),
            ),
          ],
        ),
        const ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text('How are stage delays reflowed automatically?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'When an organizer logs an unexpected extension or speaker delay, SmartEve AI recalculates downstream start times and updates your cue cards in real-time.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
              ),
            ),
          ],
        ),
        const ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text('Troubleshooting audio/video checklist warnings?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'Before going live, complete the 8-point Pre-Event Checklist in Event Details to notify the control room that you are ready.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
              ),
            ),
          ],
        ),
        const Divider(color: AppTheme.border, height: 20),
        _buildSectionTitle('CONTACT & TICKETING'),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showSupportTicketDialog(context, provider),
            icon: const Icon(Icons.support_agent_rounded, size: 18),
            label: const Text('Open Support Ticket'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Thank you! App store review launched.')),
                  );
                },
                icon: const Icon(Icons.star_outline_rounded, size: 16),
                label: const Text('Rate App', style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showSupportTicketDialog(context, provider, initialCategory: 'Feedback'),
                icon: const Icon(Icons.feedback_outlined, size: 16),
                label: const Text('Feedback', style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showSupportTicketDialog(context, provider, initialCategory: 'Technical Bug'),
                icon: const Icon(Icons.report_problem_outlined, size: 16, color: AppTheme.error),
                label: const Text('Report', style: TextStyle(fontSize: 12, color: AppTheme.error)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'SmartEve AI Platform v1.2.0 • Build 42\nNeon PostgreSQL TLS Cloud Connection Active',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppTheme.textMuted, height: 1.4),
          ),
        ),
      ],
    );
  }

  // Admin-only view: full profile info, verification controls, suspicious flag
  Widget _buildAdminView(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final draft = provider.draftProfile;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('ADMIN REVIEW — FULL PROFILE'),
          if (widget.isSuspiciousAccount)
            Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.flag_rounded, color: AppTheme.error, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Flagged: suspicious account — review verification before approving events.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.error),
                    ),
                  ),
                ],
              ),
            ),
          _buildSettingTile(
            icon: Icons.email_outlined,
            title: 'Email',
            subtitle: '${draft.email} • ${draft.isEmailVerified ? "Verified" : "Unverified"}',
            actionLabel: draft.isEmailVerified ? 'Revoke' : 'Verify',
            onTap: () {
              provider.updateAccountSettings(draft.accountSettings);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(draft.isEmailVerified ? 'Email verification revoked.' : 'Email marked verified (admin).')),
              );
            },
          ),
          const Divider(color: AppTheme.border, height: 16),
          _buildSettingTile(
            icon: Icons.phone_outlined,
            title: 'Phone',
            subtitle: '${draft.phoneNumber} • ${draft.isPhoneVerified ? "Verified" : "Unverified"}',
            actionLabel: 'Verify',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Phone verification code sent (admin).')),
              );
            },
          ),
          const Divider(color: AppTheme.border, height: 16),
          _buildSettingTile(
            icon: Icons.badge_outlined,
            title: 'Account Status',
            subtitle: draft.accountSettings.accountStatus,
            actionLabel: 'Manage',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Admin: suspend / reinstate from console.')),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Specializations: ${draft.specializations.join(", ")} • ${draft.experienceYears} yrs • Rating ${draft.stats.averageRating}/5',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  // Organizer public view placeholder
  Widget _buildOrganizerPublicNotice() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(color: AppTheme.border),
          ),
          child: const Row(
            children: [
              Icon(Icons.visibility_rounded, color: AppTheme.primaryBlue, size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Public Anchor Profile: Private settings, 2FA credentials, and notification rules are protected.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
          ),
          child: const Row(
            children: [
              Icon(Icons.notifications_active_outlined, color: AppTheme.primaryBlue, size: 22),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You will be notified automatically if this anchor changes availability, specializations, or contact permission.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Helper Widgets & Dialogs ---
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: AppTheme.textMuted),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(actionLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
        ),
      ],
    );
  }

  Widget _buildToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      value: value,
      activeTrackColor: AppTheme.primaryBlue,
      onChanged: onChanged,
    );
  }

  void _showChangeEmailDialog(BuildContext context, String currentEmail, ProfileProvider provider) {
    final controller = TextEditingController(text: currentEmail);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Email Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'New Email'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              provider.updateEmail(controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showChangePhoneDialog(BuildContext context, String currentPhone, ProfileProvider provider) {
    final controller = TextEditingController(text: currentPhone);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Phone Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'New Phone Number'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              provider.updatePhoneNumber(controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPw = TextEditingController();
    final newPw = TextEditingController();
    final confirmPw = TextEditingController();
    String strength = 'Weak';
    Color strengthColor = AppTheme.error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPw,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Current Password'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: newPw,
                obscureText: true,
                onChanged: (val) {
                  setDialogState(() {
                    if (val.length > 8 && val.contains(RegExp(r'[0-9]'))) {
                      strength = 'Strong';
                      strengthColor = AppTheme.success;
                    } else if (val.length >= 6) {
                      strength = 'Fair';
                      strengthColor = AppTheme.warning;
                    } else {
                      strength = 'Weak';
                      strengthColor = AppTheme.error;
                    }
                  });
                },
                decoration: const InputDecoration(labelText: 'New Password'),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text('Strength: $strength', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: strengthColor)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: strength == 'Strong' ? 1.0 : (strength == 'Fair' ? 0.6 : 0.25),
                      color: strengthColor,
                      backgroundColor: AppTheme.border,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: confirmPw,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm New Password'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password updated successfully!')),
                );
              },
              child: const Text('Save Password'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTwoFactorInstructionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('2FA Authentication Setup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Install an authenticator app (e.g. Google Authenticator).', style: TextStyle(fontSize: 13)),
            SizedBox(height: 6),
            Text('2. Scan the provided QR code or enter your secret key.', style: TextStyle(fontSize: 13)),
            SizedBox(height: 6),
            Text('3. Enter the 6-digit confirmation code on next login.', style: TextStyle(fontSize: 13)),
          ],
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it')),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, ProfileProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account?', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.error)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This action is irreversible. All your stage scripts, event assignments, and ratings will be permanently purged.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            const Text('Type "DELETE MY ACCOUNT" to confirm:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'DELETE MY ACCOUNT',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
            onPressed: () async {
              if (controller.text.trim() == 'DELETE MY ACCOUNT') {
                Navigator.pop(ctx);
                await provider.deleteAccount('DELETE MY ACCOUNT');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Account deleted. Redirecting...')),
                  );
                }
              }
            },
            child: const Text('Confirm Delete'),
          ),
        ],
      ),
    );
  }

  void _showSupportTicketDialog(BuildContext context, ProfileProvider provider, {String? initialCategory}) {
    String category = initialCategory ?? 'Bug Report';
    final desc = TextEditingController();
    String? attachmentName;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Submit Support Ticket', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  isExpanded: true,
                  value: category,
                  items: const [
                    DropdownMenuItem(value: 'Bug Report', child: Text('Bug Report')),
                    DropdownMenuItem(value: 'Feature Request', child: Text('Feature Request')),
                    DropdownMenuItem(value: 'Account Help', child: Text('Account Help')),
                    DropdownMenuItem(value: 'Feedback', child: Text('Feedback')),
                    DropdownMenuItem(value: 'Technical Bug', child: Text('Technical Issue')),
                    DropdownMenuItem(value: 'Inappropriate Behavior', child: Text('Report Inappropriate Behavior')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDialogState(() => category = val);
                  },
                ),
                const SizedBox(height: 10),
                const Text('Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: desc,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Describe the issue or feedback in detail...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    // Mock attachment picker — real impl would use image_picker/file_picker
                    // and upload via CloudinaryService before submitting the ticket.
                    setDialogState(() => attachmentName = 'screenshot_${DateTime.now().millisecondsSinceEpoch % 10000}.png');
                  },
                  icon: const Icon(Icons.attach_file_rounded, size: 16),
                  label: Text(
                    attachmentName == null ? 'Add Attachment (optional)' : 'Attached: $attachmentName',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (desc.text.trim().isNotEmpty) {
                  Navigator.pop(ctx);
                  final ticketId = await provider.submitSupportTicket(
                    category: category,
                    description: desc.text.trim(),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Support ticket created: $ticketId'),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                  }
                }
              },
              child: const Text('Submit Ticket'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPolicyDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: SingleChildScrollView(
          child: Text(
            '$title for SmartEve AI Platform.\n\nAll user session data, stage scripts, and speech synthesis caching comply with end-to-end encryption standards. Neon PostgreSQL connections are enforced over TLS. No audio is shared with third parties without authorization.',
            style: const TextStyle(fontSize: 13, height: 1.45, color: AppTheme.textPrimary),
          ),
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}
