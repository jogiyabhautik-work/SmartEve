import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/profile_provider.dart';
import 'widgets/profile_header_card.dart';
import 'widgets/profile_stats_section.dart';
import 'widgets/social_links_section.dart';
import 'widgets/settings_tab_view.dart';

class ProfileSettingsScreen extends StatefulWidget {
  final bool isEmbedded;
  final bool isOrganizerView;
  final bool isAdminView;
  final bool isSuspiciousAccount;
  final String? anchorIdentifier;

  const ProfileSettingsScreen({
    super.key,
    this.isEmbedded = false,
    this.isOrganizerView = false,
    this.isAdminView = false,
    this.isSuspiciousAccount = false,
    this.anchorIdentifier,
  });

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileProvider>().loadProfile(widget.anchorIdentifier);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final profile = provider.profile;

    final content = LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1200;
        final isTablet = constraints.maxWidth >= 800;

        if (isDesktop) {
          // 3-Column Desktop Layout: profile | stats+social | settings
          return SingleChildScrollView(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 96),
            child: Column(
              children: [
                if (!widget.isOrganizerView && !widget.isAdminView && (provider.isDirty || provider.isEditing))
                  _buildTopSaveBar(context, provider),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 360,
                      child: ProfileHeaderCard(profile: profile, isOrganizerView: widget.isOrganizerView),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 320,
                      child: Column(
                        children: [
                          ProfileStatsSection(stats: profile.stats),
                          const SizedBox(height: 20),
                          SocialLinksSection(socialLinks: profile.socialLinks, isOrganizerView: widget.isOrganizerView),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          SettingsTabView(
                            profile: profile,
                            isOrganizerView: widget.isOrganizerView,
                            isAdminView: widget.isAdminView,
                            isSuspiciousAccount: widget.isSuspiciousAccount,
                          ),
                          if (!widget.isOrganizerView && !widget.isAdminView) ...[
                            const SizedBox(height: 20),
                            _buildActionButtons(context, provider),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        if (isTablet) {
          // 2-Column Responsive Layout for Tablet / Desktop
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Header, Stats & Social Links
              SizedBox(
                width: 360,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 20, top: 20, right: 10, bottom: 96),
                  child: Column(
                    children: [
                      ProfileHeaderCard(profile: profile, isOrganizerView: widget.isOrganizerView),
                      const SizedBox(height: 20),
                      ProfileStatsSection(stats: profile.stats),
                      const SizedBox(height: 20),
                      SocialLinksSection(socialLinks: profile.socialLinks, isOrganizerView: widget.isOrganizerView),
                    ],
                  ),
                ),
              ),

              // Right Column: Settings Tabs & Actions
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 10, top: 20, right: 20, bottom: 96),
                  child: Column(
                    children: [
                      if (!widget.isOrganizerView && !widget.isAdminView && (provider.isDirty || provider.isEditing))
                        _buildTopSaveBar(context, provider),
                      SettingsTabView(
                        profile: profile,
                        isOrganizerView: widget.isOrganizerView,
                        isAdminView: widget.isAdminView,
                        isSuspiciousAccount: widget.isSuspiciousAccount,
                      ),
                      if (!widget.isOrganizerView && !widget.isAdminView) ...[
                        const SizedBox(height: 20),
                        _buildActionButtons(context, provider),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        // Single Column Layout for Mobile
        return SingleChildScrollView(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.isOrganizerView && !widget.isAdminView && (provider.isDirty || provider.isEditing))
                _buildTopSaveBar(context, provider),
              ProfileHeaderCard(profile: profile, isOrganizerView: widget.isOrganizerView),
              const SizedBox(height: 20),
              ProfileStatsSection(stats: profile.stats),
              const SizedBox(height: 20),
              SocialLinksSection(socialLinks: profile.socialLinks, isOrganizerView: widget.isOrganizerView),
              const SizedBox(height: 20),
              SettingsTabView(
                profile: profile,
                isOrganizerView: widget.isOrganizerView,
                isAdminView: widget.isAdminView,
                isSuspiciousAccount: widget.isSuspiciousAccount,
              ),
              if (!widget.isOrganizerView && !widget.isAdminView) ...[
                const SizedBox(height: 24),
                _buildActionButtons(context, provider),
              ],
            ],
          ),
        );
      },
    );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          widget.isOrganizerView
              ? 'Anchor Public Profile'
              : (widget.isAdminView ? 'Admin — Anchor Review' : 'Profile & Settings'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary),
        ),
        actions: [
          if (!widget.isOrganizerView && !widget.isAdminView)
            IconButton(
              icon: Icon(
                provider.isEditing ? Icons.check_circle_rounded : Icons.edit_note_rounded,
                color: provider.isEditing ? AppTheme.success : AppTheme.primaryBlue,
              ),
              tooltip: provider.isEditing ? 'Save Changes' : 'Edit Mode',
              onPressed: () {
                if (provider.isEditing) {
                  provider.saveChanges();
                } else {
                  provider.toggleEditMode(true);
                }
              },
            ),
        ],
      ),
      body: content,
    );
  }

  /// Top Save/Discard bar — mirrors bottom actions so edits can be
  /// confirmed without scrolling (per spec: Save/Discard at top and bottom).
  Widget _buildTopSaveBar(BuildContext context, ProfileProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Unsaved changes',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
            ),
          ),
          TextButton(
            onPressed: provider.discardChanges,
            child: const Text('Discard', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 4),
          ElevatedButton(
            onPressed: provider.isSaving
                ? null
                : () async {
                    final ok = await provider.saveChanges();
                    if (ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Changes saved successfully!'),
                          backgroundColor: AppTheme.success,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ProfileProvider provider) {
    final hasChanges = provider.isDirty || provider.isEditing;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          if (hasChanges) ...[
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: provider.isSaving
                        ? null
                        : () async {
                            final ok = await provider.saveChanges();
                            if (ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Changes saved successfully!'),
                                  backgroundColor: AppTheme.success,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                    icon: provider.isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    onPressed: provider.discardChanges,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Discard', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => AuthService().confirmSignOut(context),
              icon: const Icon(Icons.logout_rounded, size: 18, color: AppTheme.error),
              label: const Text('Log Out of SmartEve', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.error),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
