import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/user_profile_model.dart';
import '../../../providers/profile_provider.dart';

class ProfileHeaderCard extends StatelessWidget {
  final UserProfileModel profile;
  final bool isOrganizerView;

  const ProfileHeaderCard({
    super.key,
    required this.profile,
    this.isOrganizerView = false,
  });

  void _showAvatarSourceDialog(BuildContext context, ProfileProvider provider) {
    if (isOrganizerView) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Change Profile Photo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppTheme.primaryBlue),
                ),
                title: const Text('Take Photo with Camera', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  provider.uploadAvatar(source: ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppTheme.secondaryPurple),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  provider.uploadAvatar(source: ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditFieldDialog(BuildContext context, {
    required String title,
    required String initialValue,
    required ValueChanged<String> onSaved,
    int maxLines = 1,
    int? maxLength,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter $title',
            filled: true,
            fillColor: AppTheme.lightBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              onSaved(controller.text);
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

  void _showAddTagDialog(BuildContext context, {required String title, required ValueChanged<String> onAdd}) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g. Workshop, Hackathon, Keynote',
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
              if (controller.text.trim().isNotEmpty) {
                onAdd(controller.text.trim());
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final isEditing = provider.isEditing && !isOrganizerView;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepNavy.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row: Avatar, Edit Trigger & Name
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with camera badge
              Stack(
                children: [
                  GestureDetector(
                    onTap: () => _showAvatarSourceDialog(context, provider),
                    child: CircleAvatar(
                      radius: 42,
                      backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.12),
                      backgroundImage: profile.profileImageUrl != null && profile.profileImageUrl!.isNotEmpty
                          ? NetworkImage(profile.profileImageUrl!)
                          : null,
                      child: (profile.profileImageUrl == null || profile.profileImageUrl!.isEmpty)
                          ? Text(
                              profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : 'A',
                              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                            )
                          : null,
                    ),
                  ),
                  if (provider.isUploadingAvatar)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  if (!isOrganizerView)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _showAvatarSourceDialog(context, provider),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Full Name & Designation Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            profile.fullName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        if (!isOrganizerView)
                          IconButton(
                            icon: Icon(isEditing ? Icons.check_circle_rounded : Icons.edit_note_rounded,
                                color: isEditing ? AppTheme.success : AppTheme.primaryBlue),
                            tooltip: isEditing ? 'Finish Editing' : 'Edit Profile',
                            onPressed: () {
                              if (!isEditing) {
                                provider.toggleEditMode(true);
                              } else {
                                _showEditFieldDialog(
                                  context,
                                  title: 'Full Name',
                                  initialValue: profile.fullName,
                                  onSaved: provider.updateFullName,
                                );
                              }
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    GestureDetector(
                      onTap: isEditing
                          ? () {
                              _showEditFieldDialog(
                                context,
                                title: 'Designation',
                                initialValue: profile.designation,
                                onSaved: provider.updateDesignation,
                              );
                            }
                          : null,
                      child: Text(
                        '${profile.designation} • ${profile.collegeName}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                          decoration: isEditing ? TextDecoration.underline : TextDecoration.none,
                        ),
                      ),
                    ),
                    if (isEditing)
                      GestureDetector(
                        onTap: () => _showEditFieldDialog(
                          context,
                          title: 'College / Chapter',
                          initialValue: profile.collegeName,
                          onSaved: provider.updateCollege,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Text(
                            'Edit designation & college',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 150),
                          child: GestureDetector(
                            onTap: isEditing
                                ? () => _showEditFieldDialog(
                                      context,
                                      title: 'Timezone',
                                      initialValue: profile.timezone,
                                      onSaved: provider.updateTimezone,
                                    )
                                : null,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.access_time_rounded, size: 13, color: AppTheme.textMuted),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    profile.timezone,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Experience Badge (tap to edit years in edit mode)
                        GestureDetector(
                          onTap: isEditing
                              ? () => _showEditFieldDialog(
                                    context,
                                    title: 'Years of Experience',
                                    initialValue: '${profile.experienceYears}',
                                    keyboardType: TextInputType.number,
                                    onSaved: (val) {
                                      final years = int.tryParse(val.trim()) ?? profile.experienceYears;
                                      provider.updateExperienceYears(years);
                                    },
                                  )
                              : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.accentBlue.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.stars_rounded, size: 12, color: AppTheme.accentBlue),
                                const SizedBox(width: 4),
                                Text(
                                  '${profile.experienceYears} yrs exp',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.accentBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bio / About Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ABOUT & BIO',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: AppTheme.textMuted),
              ),
              if (isEditing)
                GestureDetector(
                  onTap: () => _showEditFieldDialog(
                    context,
                    title: 'Bio (max 500 chars)',
                    initialValue: profile.bio,
                    maxLines: 4,
                    maxLength: 500,
                    onSaved: provider.updateBio,
                  ),
                  child: const Text('Edit Bio', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            profile.bio,
            style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.45),
          ),
          const SizedBox(height: 14),

          // Languages Spoken (Tags)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'LANGUAGES',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: AppTheme.textMuted),
              ),
              if (isEditing)
                GestureDetector(
                  onTap: () => _showAddTagDialog(context, title: 'Add Language', onAdd: provider.addLanguage),
                  child: const Text('+ Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: profile.languages.map((lang) {
              return Chip(
                label: Text(lang, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                backgroundColor: AppTheme.surfaceLight,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                deleteIcon: isEditing ? const Icon(Icons.close_rounded, size: 14) : null,
                onDeleted: isEditing ? () => provider.removeLanguage(lang) : null,
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Specializations (Tags)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SPECIALIZATIONS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: AppTheme.textMuted),
              ),
              if (isEditing)
                GestureDetector(
                  onTap: () => _showAddTagDialog(context, title: 'Add Specialization', onAdd: provider.addSpecialization),
                  child: const Text('+ Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: profile.specializations.map((spec) {
              return Chip(
                avatar: const Icon(Icons.verified_outlined, size: 14, color: AppTheme.secondaryPurple),
                label: Text(spec, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.secondaryPurple)),
                backgroundColor: AppTheme.secondaryPurple.withValues(alpha: 0.08),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: AppTheme.secondaryPurple.withValues(alpha: 0.2)),
                ),
                deleteIcon: isEditing ? const Icon(Icons.close_rounded, size: 14, color: AppTheme.secondaryPurple) : null,
                onDeleted: isEditing ? () => provider.removeSpecialization(spec) : null,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.border, height: 1),
          const SizedBox(height: 14),

          // Email, Masked Phone & Verification Badges
          Row(
            children: [
              const Icon(Icons.email_outlined, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  profile.email,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
                icon: const Icon(Icons.copy_rounded, size: 16, color: AppTheme.primaryBlue),
                tooltip: 'Copy Email',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: profile.email));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Email copied to clipboard!'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(width: 6),
              // Email verified badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 12, color: AppTheme.success),
                    SizedBox(width: 3),
                    Text('Verified', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.success)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.phone_outlined, size: 16, color: AppTheme.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  profile.maskedPhoneNumber,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                ),
              ),
              if (!isOrganizerView)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                  icon: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.primaryBlue),
                  tooltip: 'Edit Phone Number',
                  onPressed: () => _showEditFieldDialog(
                    context,
                    title: 'Phone Number',
                    initialValue: profile.phoneNumber,
                    keyboardType: TextInputType.phone,
                    onSaved: provider.updatePhoneNumber,
                  ),
                ),
              const SizedBox(width: 6),
              // Phone verification badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: profile.isPhoneVerified
                      ? AppTheme.success.withValues(alpha: 0.12)
                      : AppTheme.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      profile.isPhoneVerified ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                      size: 12,
                      color: profile.isPhoneVerified ? AppTheme.success : AppTheme.warning,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      profile.isPhoneVerified ? 'Phone Verified' : 'Unverified',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: profile.isPhoneVerified ? AppTheme.success : AppTheme.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
