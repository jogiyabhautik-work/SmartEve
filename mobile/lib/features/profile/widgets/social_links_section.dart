import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/user_profile_model.dart';
import '../../../providers/profile_provider.dart';

class SocialLinksSection extends StatelessWidget {
  final SocialLinks socialLinks;
  final bool isOrganizerView;

  const SocialLinksSection({
    super.key,
    required this.socialLinks,
    this.isOrganizerView = false,
  });

  void _showEditLinkDialog(BuildContext context, {
    required String platform,
    required String initialValue,
    required ValueChanged<String> onSaved,
  }) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit $platform Link', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'https://...',
            filled: true,
            fillColor: AppTheme.lightBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              onSaved(controller.text.trim());
              Navigator.pop(ctx);
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepNavy.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PROFESSIONAL & SOCIAL LINKS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          _buildLinkTile(
            context: context,
            icon: Icons.link_rounded,
            platform: 'LinkedIn',
            url: socialLinks.linkedin,
            iconColor: const Color(0xFF0077B5),
            onEdit: () => _showEditLinkDialog(
              context,
              platform: 'LinkedIn',
              initialValue: socialLinks.linkedin,
              onSaved: (val) => provider.updateSocialLinks(linkedin: val),
            ),
          ),
          const Divider(color: AppTheme.border, height: 16),
          _buildLinkTile(
            context: context,
            icon: Icons.alternate_email_rounded,
            platform: 'Twitter / X',
            url: socialLinks.twitter,
            iconColor: const Color(0xFF0F172A),
            onEdit: () => _showEditLinkDialog(
              context,
              platform: 'Twitter / X',
              initialValue: socialLinks.twitter,
              onSaved: (val) => provider.updateSocialLinks(twitter: val),
            ),
          ),
          const Divider(color: AppTheme.border, height: 16),
          _buildLinkTile(
            context: context,
            icon: Icons.language_rounded,
            platform: 'Portfolio',
            url: socialLinks.portfolio,
            iconColor: AppTheme.accentBlue,
            onEdit: () => _showEditLinkDialog(
              context,
              platform: 'Portfolio',
              initialValue: socialLinks.portfolio,
              onSaved: (val) => provider.updateSocialLinks(portfolio: val),
            ),
          ),
          const Divider(color: AppTheme.border, height: 16),
          _buildLinkTile(
            context: context,
            icon: Icons.smart_display_rounded,
            platform: 'YouTube',
            url: socialLinks.youtube,
            iconColor: const Color(0xFFFF0000),
            onEdit: () => _showEditLinkDialog(
              context,
              platform: 'YouTube',
              initialValue: socialLinks.youtube,
              onSaved: (val) => provider.updateSocialLinks(youtube: val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile({
    required BuildContext context,
    required IconData icon,
    required String platform,
    required String url,
    required Color iconColor,
    required VoidCallback onEdit,
  }) {
    final hasUrl = url.isNotEmpty;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                platform,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              Text(
                hasUrl ? url : 'Not connected',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: hasUrl ? AppTheme.textSecondary : AppTheme.textMuted,
                  fontStyle: hasUrl ? FontStyle.normal : FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        if (!isOrganizerView)
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.primaryBlue),
            tooltip: 'Edit $platform URL',
            onPressed: onEdit,
          ),
      ],
    );
  }
}
