import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/network/api_client.dart';
import '../core/services/auth_service.dart';
import '../core/services/cloudinary_service.dart';
import '../models/user_profile_model.dart';

class ProfileProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final CloudinaryService _cloudinary = CloudinaryService();

  UserProfileModel _profile = const UserProfileModel(
    id: 'usr_jordan',
    email: 'jordan@stageflow.io',
    fullName: 'Jordan Hayes',
  );

  late UserProfileModel _draftProfile;

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  bool _isEditing = false;
  String? _errorMessage;
  String? _successMessage;

  ProfileProvider() {
    _draftProfile = _profile;
  }

  // Getters
  UserProfileModel get profile => _isEditing ? _draftProfile : _profile;
  UserProfileModel get savedProfile => _profile;
  UserProfileModel get draftProfile => _draftProfile;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isUploadingAvatar => _isUploadingAvatar;
  bool get isEditing => _isEditing;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  bool get isDirty {
    // Profile identity fields
    if (_draftProfile.fullName != _profile.fullName ||
        _draftProfile.designation != _profile.designation ||
        _draftProfile.collegeName != _profile.collegeName ||
        _draftProfile.timezone != _profile.timezone ||
        _draftProfile.bio != _profile.bio ||
        _draftProfile.experienceYears != _profile.experienceYears ||
        _draftProfile.phoneNumber != _profile.phoneNumber ||
        _draftProfile.email != _profile.email ||
        _draftProfile.profileImageUrl != _profile.profileImageUrl ||
        _draftProfile.languages.join(',') != _profile.languages.join(',') ||
        _draftProfile.specializations.join(',') != _profile.specializations.join(',') ||
        _draftProfile.socialLinks.linkedin != _profile.socialLinks.linkedin ||
        _draftProfile.socialLinks.twitter != _profile.socialLinks.twitter ||
        _draftProfile.socialLinks.portfolio != _profile.socialLinks.portfolio ||
        _draftProfile.socialLinks.youtube != _profile.socialLinks.youtube) {
      return true;
    }
    // Account / notification / app / privacy — compare serialized maps
    // so any toggle, dropdown, or quiet-hours change marks dirty.
    if (_draftProfile.accountSettings.toJson().toString() !=
            _profile.accountSettings.toJson().toString() ||
        _draftProfile.notificationPreferences.toJson().toString() !=
            _profile.notificationPreferences.toJson().toString() ||
        _draftProfile.appPreferences.toJson().toString() !=
            _profile.appPreferences.toJson().toString() ||
        _draftProfile.privacySettings.toJson().toString() !=
            _profile.privacySettings.toJson().toString()) {
      return true;
    }
    return false;
  }

  /// Loads profile from Neon DB via API, falling back to local user session
  Future<void> loadProfile([String? emailOrId]) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      AppUser? user;
      try {
        user = AuthService().currentAppUser;
      } catch (_) {}

      final target = emailOrId ?? user?.email ?? 'jordan@stageflow.io';

      final res = await _apiClient.get('/user/profile/${Uri.encodeComponent(target)}');
      if (res.success && res.data is Map<String, dynamic>) {
        _profile = UserProfileModel.fromJson(res.data as Map<String, dynamic>);
      } else {
        // Fallback default populated with current app user
        _profile = UserProfileModel(
          id: user?.uid ?? 'usr_current',
          email: user?.email ?? target,
          fullName: (user?.fullName.isNotEmpty == true) ? user!.fullName : 'Jordan Hayes',
          role: user?.role ?? 'anchor',
        );
      }
    } catch (e) {
      debugPrint("⚠️ [ProfileProvider] Failed to load profile from backend: $e");
      AppUser? user;
      try {
        user = AuthService().currentAppUser;
      } catch (_) {}

      _profile = UserProfileModel(
        id: user?.uid ?? 'usr_local',
        email: user?.email ?? 'anchor@smarteve.io',
        fullName: (user?.fullName.isNotEmpty == true) ? user!.fullName : 'Jordan Hayes',
        role: user?.role ?? 'anchor',
      );
    } finally {
      _draftProfile = _profile;
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleEditMode([bool? force]) {
    _isEditing = force ?? !_isEditing;
    if (_isEditing) {
      _draftProfile = _profile;
    }
    notifyListeners();
  }

  void updateFullName(String val) {
    _draftProfile = _draftProfile.copyWith(fullName: val.trim());
    notifyListeners();
  }

  void updateDesignation(String val) {
    _draftProfile = _draftProfile.copyWith(designation: val.trim());
    notifyListeners();
  }

  void updateCollege(String val) {
    _draftProfile = _draftProfile.copyWith(collegeName: val.trim());
    notifyListeners();
  }

  void updateTimezone(String val) {
    _draftProfile = _draftProfile.copyWith(timezone: val.trim());
    notifyListeners();
  }

  void updateBio(String val) {
    final trimmed = val.trim();
    final capped = trimmed.length > 500 ? trimmed.substring(0, 500) : trimmed;
    _draftProfile = _draftProfile.copyWith(bio: capped);
    notifyListeners();
  }

  void updateExperienceYears(int years) {
    _draftProfile = _draftProfile.copyWith(experienceYears: years.clamp(0, 60));
    notifyListeners();
  }

  void updateEmail(String val) {
    _draftProfile = _draftProfile.copyWith(email: val.trim());
    notifyListeners();
  }

  void updatePhoneNumber(String val) {
    _draftProfile = _draftProfile.copyWith(phoneNumber: val.trim());
    notifyListeners();
  }

  void addLanguage(String lang) {
    final clean = lang.trim();
    if (clean.isNotEmpty && !_draftProfile.languages.contains(clean)) {
      final updated = List<String>.from(_draftProfile.languages)..add(clean);
      _draftProfile = _draftProfile.copyWith(languages: updated);
      notifyListeners();
    }
  }

  void removeLanguage(String lang) {
    final updated = List<String>.from(_draftProfile.languages)..remove(lang);
    _draftProfile = _draftProfile.copyWith(languages: updated);
    notifyListeners();
  }

  void addSpecialization(String spec) {
    final clean = spec.trim();
    if (clean.isNotEmpty && !_draftProfile.specializations.contains(clean)) {
      final updated = List<String>.from(_draftProfile.specializations)..add(clean);
      _draftProfile = _draftProfile.copyWith(specializations: updated);
      notifyListeners();
    }
  }

  void removeSpecialization(String spec) {
    final updated = List<String>.from(_draftProfile.specializations)..remove(spec);
    _draftProfile = _draftProfile.copyWith(specializations: updated);
    notifyListeners();
  }

  void updateSocialLinks({String? linkedin, String? twitter, String? portfolio, String? youtube}) {
    _draftProfile = _draftProfile.copyWith(
      socialLinks: _draftProfile.socialLinks.copyWith(
        linkedin: linkedin,
        twitter: twitter,
        portfolio: portfolio,
        youtube: youtube,
      ),
    );
    notifyListeners();
  }

  void updateAccountSettings(AccountSettings settings) {
    _draftProfile = _draftProfile.copyWith(accountSettings: settings);
    notifyListeners();
  }

  void updateNotificationPreferences(NotificationPreferences prefs) {
    _draftProfile = _draftProfile.copyWith(notificationPreferences: prefs);
    notifyListeners();
  }

  void updateAppPreferences(AppPreferences prefs) {
    _draftProfile = _draftProfile.copyWith(appPreferences: prefs);
    notifyListeners();
  }

  void updatePrivacySettings(PrivacySecuritySettings settings) {
    _draftProfile = _draftProfile.copyWith(privacySettings: settings);
    notifyListeners();
  }

  void unblockUser(String userName) {
    final updated = List<String>.from(_draftProfile.privacySettings.blockedUsers)..remove(userName);
    _draftProfile = _draftProfile.copyWith(
      privacySettings: _draftProfile.privacySettings.copyWith(blockedUsers: updated),
    );
    notifyListeners();
  }

  void blockUser(String userName) {
    final clean = userName.trim();
    if (clean.isNotEmpty && !_draftProfile.privacySettings.blockedUsers.contains(clean)) {
      final updated = List<String>.from(_draftProfile.privacySettings.blockedUsers)..add(clean);
      _draftProfile = _draftProfile.copyWith(
        privacySettings: _draftProfile.privacySettings.copyWith(blockedUsers: updated),
      );
      notifyListeners();
    }
  }

  /// Uploads avatar image to Cloudinary and updates profile URL
  Future<bool> uploadAvatar({ImageSource source = ImageSource.gallery}) async {
    _isUploadingAvatar = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final uploadedUrl = await _cloudinary.pickAndUploadProfileAvatar(source: source);
      if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
        _draftProfile = _draftProfile.copyWith(profileImageUrl: uploadedUrl);
        _profile = _profile.copyWith(profileImageUrl: uploadedUrl);

        // Auto-persist uploaded avatar URL to backend
        await _apiClient.put('/user/profile', {
          'email': _profile.email,
          'profileImageUrl': uploadedUrl,
        });

        _isUploadingAvatar = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = "Failed to upload avatar: $e";
    } finally {
      _isUploadingAvatar = false;
      notifyListeners();
    }
    return false;
  }

  /// Saves dirty profile edits to Neon PostgreSQL via backend API
  Future<bool> saveChanges() async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final payload = _draftProfile.toJson();
      final res = await _apiClient.put('/user/profile', payload);

      if (res.success) {
        _profile = _draftProfile;
        _isEditing = false;
        _successMessage = "Profile and settings updated successfully!";
        _isSaving = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = res.errorMessage ?? "Could not save changes to server.";
      }
    } catch (e) {
      // In offline / fallback mode, still commit locally
      _profile = _draftProfile;
      _isEditing = false;
      _successMessage = "Changes saved to local device cache.";
    } finally {
      _isSaving = false;
      notifyListeners();
    }
    return true;
  }

  void discardChanges() {
    _draftProfile = _profile;
    _isEditing = false;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Submits a support ticket through the backend
  Future<String?> submitSupportTicket({
    required String category,
    required String description,
    String? attachmentUrl,
  }) async {
    try {
      final res = await _apiClient.post('/user/support-ticket', {
        'email': _profile.email,
        'category': category,
        'description': description,
        'attachmentUrl': attachmentUrl,
        'appVersion': 'SmartEve AI v1.2.0 (Build 42)',
      });

      if (res.success && res.data != null) {
        return (res.data['ticketId'] as String?) ?? 'TICK-RECEIVED';
      }
    } catch (e) {
      debugPrint("Support ticket error: $e");
    }
    return 'TICK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  }

  /// Deletes user account
  Future<bool> deleteAccount(String confirmPhrase) async {
    try {
      final res = await _apiClient.post('/user/delete-account', {
        'email': _profile.email,
        'confirmPhrase': confirmPhrase,
      });
      return res.success;
    } catch (e) {
      debugPrint("Delete account error: $e");
      return false;
    }
  }
}
