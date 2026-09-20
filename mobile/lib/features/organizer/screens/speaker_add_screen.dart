import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../models/speaker_model.dart';
import '../../../providers/event_provider.dart';

class SpeakerAddScreen extends StatefulWidget {
  final SpeakerModel? speakerToEdit;
  final String? targetEventId;

  const SpeakerAddScreen({
    super.key,
    this.speakerToEdit,
    this.targetEventId,
  });

  @override
  State<SpeakerAddScreen> createState() => _SpeakerAddScreenState();
}

class _SpeakerAddScreenState extends State<SpeakerAddScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _designationController;
  late TextEditingController _organizationController;
  late TextEditingController _topicController;
  late TextEditingController _bioController;
  late TextEditingController _photoUrlController;

  String _status = 'expected';
  bool _isSaving = false;
  bool _isUploadingImage = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final edit = widget.speakerToEdit;
    _nameController = TextEditingController(text: edit?.name ?? '');
    _designationController = TextEditingController(text: edit?.designation ?? '');
    _organizationController = TextEditingController(text: edit?.organization ?? '');
    _topicController = TextEditingController(text: edit?.topic ?? '');
    _bioController = TextEditingController(text: edit?.bio ?? '');
    _photoUrlController = TextEditingController(text: edit?.photoUrl ?? '');
    _status = edit?.status ?? 'expected';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _designationController.dispose();
    _organizationController.dispose();
    _topicController.dispose();
    _bioController.dispose();
    _photoUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() => _isUploadingImage = true);

        // Upload image to Cloudinary CDN in dedicated project folder 'smarteve_speakers'
        final cloudinaryUrl = await CloudinaryService().uploadImage(pickedFile, folder: 'smarteve_speakers');

        if (!mounted) return;
        setState(() {
          _isUploadingImage = false;
          if (cloudinaryUrl != null) {
            _photoUrlController.text = cloudinaryUrl;
          }
        });

        if (cloudinaryUrl != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.cloud_done_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('☁️ Profile photo uploaded to Cloudinary CDN!\n$cloudinaryUrl', style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              backgroundColor: AppTheme.liveGreen,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Cloudinary upload failed. Please check internet connection.'),
              backgroundColor: AppTheme.dangerRose,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingImage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not pick or upload image: $e'),
          backgroundColor: AppTheme.dangerRose,
        ),
      );
    }
  }

  void _handleSaveSpeaker() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      final newSpeaker = SpeakerModel(
        id: widget.speakerToEdit?.id ?? 'spk-${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        designation: _designationController.text.trim(),
        organization: _organizationController.text.trim(),
        topic: _topicController.text.trim(),
        bio: _bioController.text.trim(),
        photoUrl: _photoUrlController.text.trim().isNotEmpty ? _photoUrlController.text.trim() : null,
        status: _status,
      );

      final success = await context.read<EventProvider>().addSpeaker(
            newSpeaker,
            eventId: widget.targetEventId,
            originalId: widget.speakerToEdit?.id,
          );

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(child: Text('🎤 Speaker "${newSpeaker.name}" saved to Neon DB!')),
              ],
            ),
            backgroundColor: AppTheme.liveGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.speakerToEdit != null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Speaker Profile' : 'Add New Speaker / Guest',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.liveGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.liveGreen.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.mic_external_on_rounded, color: AppTheme.liveGreen, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Speaker Profile Setup',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Register keynote speakers, VIP guests, and panel moderators for AI intro generation.',
                              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Speaker Name
                const Text(
                  'FULL NAME *',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'e.g. Dr. Aris Vance',
                    hintStyle: const TextStyle(color: AppTheme.textMuted),
                    prefixIcon: const Icon(Icons.person_rounded, color: AppTheme.primaryBlue),
                    filled: true,
                    fillColor: AppTheme.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2)),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter speaker full name' : null,
                ),
                const SizedBox(height: 20),

                // Designation & Organization Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DESIGNATION / ROLE *',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _designationController,
                            style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'e.g. VP of Applied AI',
                              hintStyle: const TextStyle(color: AppTheme.textMuted),
                              prefixIcon: const Icon(Icons.badge_rounded, color: AppTheme.primaryBlue),
                              filled: true,
                              fillColor: AppTheme.surface,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ORGANIZATION *',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _organizationController,
                            style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'e.g. DeepScale Labs',
                              hintStyle: const TextStyle(color: AppTheme.textMuted),
                              prefixIcon: const Icon(Icons.business_rounded, color: AppTheme.primaryBlue),
                              filled: true,
                              fillColor: AppTheme.surface,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
                            ),
                            validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Speaking Topic
                const Text(
                  'SPEAKING TOPIC / PRESENTATION *',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _topicController,
                  style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'e.g. Autonomous Agents in High-Stakes Operations',
                    hintStyle: const TextStyle(color: AppTheme.textMuted),
                    prefixIcon: const Icon(Icons.topic_rounded, color: AppTheme.primaryBlue),
                    filled: true,
                    fillColor: AppTheme.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2)),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter speaking topic' : null,
                ),
                const SizedBox(height: 20),

                // Status Dropdown
                const Text(
                  'ARRIVAL STATUS',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  dropdownColor: AppTheme.surface,
                  style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.check_circle_outline_rounded, color: AppTheme.primaryBlue),
                    filled: true,
                    fillColor: AppTheme.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'expected', child: Text('Expected / Invited')),
                    DropdownMenuItem(value: 'arrived', child: Text('Arrived at Venue')),
                    DropdownMenuItem(value: 'absent', child: Text('Absent / Delayed')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _status = val);
                  },
                ),
                const SizedBox(height: 20),

                // Speaker Bio
                const Text(
                  'SPEAKER BIO (Used for AI Script Generation) *',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Brief summary of the speaker background, achievements, and key focus...',
                    hintStyle: const TextStyle(color: AppTheme.textMuted),
                    filled: true,
                    fillColor: AppTheme.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2)),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter speaker bio' : null,
                ),
                const SizedBox(height: 20),

                // Speaker Photo & Gallery Selection
                const Text(
                  'SPEAKER AVATAR / PROFILE PHOTO',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Live Image Preview Avatar
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.15),
                            backgroundImage: _photoUrlController.text.isNotEmpty && !_isUploadingImage
                                ? (_photoUrlController.text.startsWith('http://') || _photoUrlController.text.startsWith('https://')
                                    ? NetworkImage(_photoUrlController.text) as ImageProvider
                                    : FileImage(File(_photoUrlController.text)))
                                : null,
                            child: _isUploadingImage
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.primaryBlue),
                                  )
                                : (_photoUrlController.text.isEmpty
                                    ? const Icon(Icons.person_rounded, size: 36, color: AppTheme.primaryBlue)
                                    : null),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isUploadingImage ? 'Uploading to Cloudinary CDN...' : 'Choose Profile Photo',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isUploadingImage
                                      ? 'Transferring image to Cloudinary CDN server...'
                                      : 'Pick from Gallery or Camera. Uploads automatically to Cloudinary.',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _isUploadingImage ? null : () => _pickImage(ImageSource.gallery),
                                      icon: const Icon(Icons.photo_library_rounded, size: 16, color: Colors.white),
                                      label: const Text('GALLERY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryBlue,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: _isUploadingImage ? null : () => _pickImage(ImageSource.camera),
                                      icon: const Icon(Icons.camera_alt_rounded, size: 16, color: AppTheme.primaryBlue),
                                      label: const Text('CAMERA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: AppTheme.primaryBlue),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1, color: AppTheme.border),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _photoUrlController,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Or enter image file path / Cloudinary URL...',
                          hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          prefixIcon: const Icon(Icons.link_rounded, color: AppTheme.primaryBlue, size: 20),
                          suffixIcon: _photoUrlController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textMuted),
                                  onPressed: () => setState(() => _photoUrlController.clear()),
                                )
                              : null,
                          filled: true,
                          fillColor: AppTheme.surfaceLight,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.border)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSaveSpeaker,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.liveGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : Text(
                            isEditing ? 'UPDATE SPEAKER PROFILE' : 'SAVE SPEAKER TO NEON DB',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
