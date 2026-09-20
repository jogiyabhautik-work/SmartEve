import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../network/api_client.dart';
import '../theme/app_theme.dart';
import '../../features/auth/login_screen.dart';
import 'neon_database_service.dart';
import '../../features/auth/models/registration_data.dart';

class AppUser {
  final String uid;
  final String email;
  final String fullName;
  final String role; // 'organizer', 'anchor', 'admin'
  final String? neonId;
  final bool isFallback;

  AppUser({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    this.neonId,
    this.isFallback = false,
  });
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _prefSessionActive = 'smarteve_session_active';
  static const String _prefUid = 'smarteve_uid';
  static const String _prefEmail = 'smarteve_email';
  static const String _prefFullName = 'smarteve_fullname';
  static const String _prefRole = 'smarteve_role';
  static const String _prefNeonId = 'smarteve_neon_id';

  FirebaseAuth? _authInstance;
  FirebaseAuth get _auth => _authInstance ??= FirebaseAuth.instance;
  final ApiClient _apiClient = ApiClient();
  final NeonDatabaseService _neonDb = NeonDatabaseService();

  AppUser? _currentAppUser;
  AppUser? get currentAppUser => _currentAppUser;
  String get currentUserRole => _currentAppUser?.role ?? 'organizer';
  User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }
  Stream<User?> get authStateChanges {
    try {
      return _auth.authStateChanges();
    } catch (_) {
      return const Stream.empty();
    }
  }

  Future<void> _persistSession(AppUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefSessionActive, true);
      await prefs.setString(_prefUid, user.uid);
      await prefs.setString(_prefEmail, user.email);
      await prefs.setString(_prefFullName, user.fullName);
      await prefs.setString(_prefRole, user.role.toLowerCase());
      if (user.neonId != null && user.neonId!.isNotEmpty) {
        await prefs.setString(_prefNeonId, user.neonId!);
      } else {
        await prefs.remove(_prefNeonId);
      }
      debugPrint("💾 [Session] Persisted ${user.role} session for ${user.email}");
    } catch (e) {
      debugPrint("⚠️ [Session] Failed to persist session: $e");
    }
  }

  Future<void> _clearPersistedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefSessionActive);
      await prefs.remove(_prefUid);
      await prefs.remove(_prefEmail);
      await prefs.remove(_prefFullName);
      await prefs.remove(_prefRole);
      await prefs.remove(_prefNeonId);
      debugPrint("🧹 [Session] Cleared local session");
    } catch (e) {
      debugPrint("⚠️ [Session] Failed to clear local session: $e");
    }
  }

  /// Restores active session on app startup / reopen
  Future<AppUser?> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isActive = prefs.getBool(_prefSessionActive) ?? false;
      final savedEmail = prefs.getString(_prefEmail);

      // 1. Check local persistent storage first
      if (isActive && savedEmail != null && savedEmail.isNotEmpty) {
        final uid = prefs.getString(_prefUid) ?? 'user_restored';
        final fullName = prefs.getString(_prefFullName) ?? savedEmail.split('@').first;
        String role = prefs.getString(_prefRole) ?? 'organizer';
        final neonId = prefs.getString(_prefNeonId);

        // Attempt non-blocking refresh of role from Neon/Supabase DB
        try {
          final neonUser = await _neonDb.getUserByEmail(savedEmail);
          if (neonUser != null && neonUser['role'] != null) {
            role = neonUser['role'].toString().toLowerCase();
            await prefs.setString(_prefRole, role);
          }
        } catch (_) {}

        _currentAppUser = AppUser(
          uid: uid,
          email: savedEmail,
          fullName: fullName,
          role: role,
          neonId: neonId,
        );
        debugPrint("🚀 [Session] Restored active session: ${_currentAppUser!.fullName} (${_currentAppUser!.role})");
        return _currentAppUser;
      }

      // 2. Check Firebase Auth if local prefs was empty but Firebase user is active
      User? firebaseUser;
      try {
        firebaseUser = _auth.currentUser;
      } catch (_) {}

      if (firebaseUser != null && firebaseUser.email != null) {
        final email = firebaseUser.email!.trim().toLowerCase();
        String fullName = email.split('@').first;
        String? neonId;
        String role = 'organizer';

        final rawDisplayName = firebaseUser.displayName ?? '';
        if (rawDisplayName.contains('|')) {
          final parts = rawDisplayName.split('|');
          if (parts.isNotEmpty && parts[0].isNotEmpty) fullName = parts[0];
          if (parts.length > 1 && parts[1].isNotEmpty) neonId = parts[1];
          if (parts.length > 2 && parts[2].isNotEmpty) role = parts[2].toLowerCase();
        } else if (rawDisplayName.isNotEmpty) {
          fullName = rawDisplayName;
        }

        // Verify with Neon DB
        try {
          final neonUser = await _neonDb.getUserByEmail(email);
          if (neonUser != null && neonUser['role'] != null) {
            role = neonUser['role'].toString().toLowerCase();
            neonId = neonUser['id']?.toString() ?? neonId;
            fullName = neonUser['full_name']?.toString() ?? fullName;
          }
        } catch (_) {}

        _currentAppUser = AppUser(
          uid: firebaseUser.uid,
          email: email,
          fullName: fullName,
          role: role,
          neonId: neonId,
        );

        await _persistSession(_currentAppUser!);
        debugPrint("🚀 [Session] Restored Firebase Auth session: ${_currentAppUser!.fullName} (${_currentAppUser!.role})");
        return _currentAppUser;
      }

      return null;
    } catch (e) {
      debugPrint("⚠️ [Session] Error restoring session: $e");
      return null;
    }
  }

  /// Displays a logout confirmation dialog. Upon confirmation, signs out and redirects to LoginScreen.
  Future<bool> confirmSignOut(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: AppTheme.error, size: 24),
              SizedBox(width: 10),
              Text(
                'Confirm Logout',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to log out of SmartEve? You will need to sign in again to access your live stage dashboard.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              child: const Text(
                'Log Out',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await signOut();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully.'),
            backgroundColor: AppTheme.primaryBlue,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
      return true;
    }
    return false;
  }

  bool _isConfigError(dynamic e) {
    final str = e.toString().toUpperCase();
    return str.contains('CONFIGURATION_NOT_FOUND') ||
        str.contains('OPERATION-NOT-ALLOWED') ||
        str.contains('IDENTITYTOOLKIT');
  }

  /// 1. Register an Organizer
  /// Flow: 
  ///  1. Prefer auth in Firebase first
  ///  2. Save data in Neon Tech directly (cloud-to-database over TLS)
  ///  3. After saving in Neon Tech, save the Neon UUID back into Firebase user profile
  ///  4. Resilience: If Firebase fails with CONFIGURATION_NOT_FOUND, fallback directly to Neon DB
  Future<AppUser> registerOrganizer({
    required OrganizerRegistrationModel data,
  }) async {
    final cleanEmail = data.email.trim().toLowerCase();
    final cleanName = data.fullName.trim();

    final profileData = {
      'designation': data.designation,
      'department': data.department,
      'studentId': data.studentId,
      'collegeName': data.collegeName,
      'alternatePhone': data.alternatePhone,
      'eventsOrganized': data.eventsOrganized,
      'yearsOfExperience': data.yearsOfExperience,
      'linkedin': data.linkedin,
      'twitter': data.twitter,
      'website': data.website,
      'emergencyContactName': data.emergencyContactName,
      'emergencyContactPhone': data.emergencyContactPhone,
      'language': data.language,
      'timezone': data.timezone,
      'receiveNotifications': data.receiveNotifications,
      'receiveEmails': data.receiveEmails,
      'termsAccepted': data.termsAccepted,
      'privacyAccepted': data.privacyAccepted,
    };

    UserCredential? credential;
    String effectiveUid;

    // STEP 1: Attempt Firebase Auth registration first
    try {
      if (_auth.currentUser != null && _auth.currentUser!.isAnonymous) {
        await _auth.signOut();
      }

      credential = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: data.password,
      );
      effectiveUid = credential.user!.uid;
      debugPrint("✅ [1/3] Firebase Auth user created: $effectiveUid");
    } catch (e) {
      if (_isConfigError(e)) {
        debugPrint("⚠️ Firebase Auth CONFIGURATION_NOT_FOUND detected. Activating Resilient Neon DB fallback...");
        effectiveUid = 'local_${const Uuid().v4()}';
      } else if (e is FirebaseAuthException) {
        throw _translateFirebaseError(e);
      } else {
        rethrow;
      }
    }

    // STEP 2: Save data into Neon Tech PostgreSQL directly
    String? neonId;
    try {
      neonId = await _neonDb.saveUser(
        firebaseUid: effectiveUid,
        email: cleanEmail,
        fullName: cleanName,
        role: 'organizer',
        phoneNumber: data.phoneNumber.trim().isNotEmpty ? data.phoneNumber.trim() : null,
        bio: data.bio.trim().isNotEmpty ? data.bio.trim() : null,
        profileImageUrl: data.profileImageUrl,
        profileData: profileData,
      );
      if (neonId != null) {
        debugPrint("✅ [2/3] Organizer saved directly to Neon Tech DB. Neon UUID: $neonId");
      }
    } catch (e) {
      debugPrint("⚠️ Direct Neon DB save error: $e");
    }

    // Also attempt backend sync if backend server is available
    if (neonId == null) {
      try {
        final response = await _apiClient.post('/auth/register', {
          'firebaseUid': effectiveUid,
          'email': cleanEmail,
          'fullName': cleanName,
          'role': 'organizer',
          'phoneNumber': data.phoneNumber.trim().isNotEmpty ? data.phoneNumber.trim() : null,
          'bio': data.bio.trim().isNotEmpty ? data.bio.trim() : null,
          'profileImageUrl': data.profileImageUrl,
          'profileData': profileData,
        });
        if (response.success && response.data != null) {
          neonId = response.data['id']?.toString();
          debugPrint("✅ [2/3] Organizer synced to Neon DB via backend API: $neonId");
        }
      } catch (e) {
        debugPrint("⚠️ Backend API sync error: $e");
      }
    }

    // STEP 3: After saving in Neon Tech, save the Neon UUID back into Firebase user profile
    if (credential != null && credential.user != null) {
      try {
        final displayNameWithNeon = "$cleanName|${neonId ?? ''}|organizer";
        await credential.user!.updateDisplayName(displayNameWithNeon);
        debugPrint("✅ [3/3] Saved Neon UUID ($neonId) and role (organizer) into Firebase user displayName: $displayNameWithNeon");
      } catch (e) {
        debugPrint("⚠️ Could not update Firebase display name: $e");
      }
    }

    _currentAppUser = AppUser(
      uid: effectiveUid,
      email: cleanEmail,
      fullName: cleanName,
      role: 'organizer',
      neonId: neonId,
      isFallback: credential == null,
    );

    return _currentAppUser!;
  }

  /// 2. Register an Anchor
  /// Flow: 
  ///  1. Prefer auth in Firebase first
  ///  2. Save data in Neon Tech directly (cloud-to-database over TLS)
  ///  3. After saving in Neon Tech, save the Neon UUID back into Firebase user profile
  ///  4. Resilience: If Firebase fails with CONFIGURATION_NOT_FOUND, fallback directly to Neon DB
  Future<AppUser> registerAnchor({
    required AnchorRegistrationModel data,
  }) async {
    final cleanEmail = data.email.trim().toLowerCase();
    final cleanName = data.fullName.trim();

    final profileData = {
      'designation': data.designation,
      'department': data.department,
      'studentId': data.studentId,
      'collegeName': data.collegeName,
      'alternatePhone': data.alternatePhone,
      'anchoringExperience': data.anchoringExperience,
      'previousEvents': data.previousEvents,
      'specializations': data.specializations,
      'languagesSpoken': data.languagesSpoken,
      'languagePreference': data.languagePreference,
      'timezone': data.timezone,
      'preferredEventTime': data.preferredEventTime,
      'linkedin': data.linkedin,
      'twitter': data.twitter,
      'portfolio': data.portfolio,
      'youtube': data.youtube,
      'deviceType': data.deviceType,
      'notificationPreference': data.notificationPreference,
      'emergencyContactName': data.emergencyContactName,
      'emergencyContactPhone': data.emergencyContactPhone,
      'receiveEventInvitations': data.receiveEventInvitations,
      'receiveNotifications': data.receiveNotifications,
      'allowProfilePublic': data.allowProfilePublic,
      'termsAccepted': data.termsAccepted,
      'privacyAccepted': data.privacyAccepted,
      'backgroundCheckConsent': data.backgroundCheckConsent,
    };

    UserCredential? credential;
    String effectiveUid;

    // STEP 1: Attempt Firebase Auth registration first
    try {
      if (_auth.currentUser != null && _auth.currentUser!.isAnonymous) {
        await _auth.signOut();
      }

      credential = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: data.password,
      );
      effectiveUid = credential.user!.uid;
      debugPrint("✅ [1/3] Firebase Auth anchor created: $effectiveUid");
    } catch (e) {
      if (_isConfigError(e)) {
        debugPrint("⚠️ Firebase Auth CONFIGURATION_NOT_FOUND detected. Activating Resilient Neon DB fallback...");
        effectiveUid = 'local_${const Uuid().v4()}';
      } else if (e is FirebaseAuthException) {
        throw _translateFirebaseError(e);
      } else {
        rethrow;
      }
    }

    // STEP 2: Save data into Neon Tech PostgreSQL directly
    String? neonId;
    try {
      neonId = await _neonDb.saveUser(
        firebaseUid: effectiveUid,
        email: cleanEmail,
        fullName: cleanName,
        role: 'anchor',
        phoneNumber: data.phoneNumber.trim().isNotEmpty ? data.phoneNumber.trim() : null,
        bio: data.bio.trim().isNotEmpty ? data.bio.trim() : null,
        profileImageUrl: data.profileImageUrl,
        profileData: profileData,
      );
      if (neonId != null) {
        debugPrint("✅ [2/3] Anchor saved directly to Neon Tech DB. Neon UUID: $neonId");
      }
    } catch (e) {
      debugPrint("⚠️ Direct Neon DB save error: $e");
    }

    // Also attempt backend sync if backend server is available
    if (neonId == null) {
      try {
        final response = await _apiClient.post('/auth/register', {
          'firebaseUid': effectiveUid,
          'email': cleanEmail,
          'fullName': cleanName,
          'role': 'anchor',
          'phoneNumber': data.phoneNumber.trim().isNotEmpty ? data.phoneNumber.trim() : null,
          'bio': data.bio.trim().isNotEmpty ? data.bio.trim() : null,
          'profileImageUrl': data.profileImageUrl,
          'profileData': profileData,
        });
        if (response.success && response.data != null) {
          neonId = response.data['id']?.toString();
          debugPrint("✅ [2/3] Anchor synced to Neon DB via backend API: $neonId");
        }
      } catch (e) {
        debugPrint("⚠️ Backend API sync error: $e");
      }
    }

    // STEP 3: After saving in Neon Tech, save the Neon UUID back into Firebase user profile
    if (credential != null && credential.user != null) {
      try {
        final displayNameWithNeon = "$cleanName|${neonId ?? ''}|anchor";
        await credential.user!.updateDisplayName(displayNameWithNeon);
        debugPrint("✅ [3/3] Saved Neon UUID ($neonId) and role (anchor) into Firebase user displayName: $displayNameWithNeon");
      } catch (e) {
        debugPrint("⚠️ Could not update Firebase display name: $e");
      }
    }

    _currentAppUser = AppUser(
      uid: effectiveUid,
      email: cleanEmail,
      fullName: cleanName,
      role: 'anchor',
      neonId: neonId,
      isFallback: credential == null,
    );

    return _currentAppUser!;
  }

  /// 3. Sign In with Email & Password
  /// Flow:
  ///  1. Attempt Firebase Auth login first
  ///  2. Fetch profile from Neon Tech directly (or sync if missing)
  ///  3. Cross-reference Neon UUID into Firebase Auth if missing
  ///  4. If Firebase fails with config error, fallback to Neon DB directly
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();

    // Check quick demo shortcuts
    if (cleanEmail == 'alex@technova.io') {
      return await demoLogin('organizer');
    }
    if (cleanEmail == 'jordan@stageflow.io') {
      return await demoLogin('anchor');
    }

    try {
      // 1. Authenticate with Firebase Auth first
      final credential = await _auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      final firebaseUser = credential.user!;
      String? neonId;
      String? role;
      String fullName = cleanEmail.split('@').first;

      // Extract existing Neon UUID and role from displayName if present
      final rawDisplayName = firebaseUser.displayName ?? '';
      if (rawDisplayName.contains('|')) {
        final parts = rawDisplayName.split('|');
        if (parts.isNotEmpty && parts[0].trim().isNotEmpty) fullName = parts[0].trim();
        if (parts.length > 1 && parts[1].trim().isNotEmpty) neonId = parts[1].trim();
        if (parts.length > 2 && parts[2].trim().isNotEmpty) role = parts[2].trim().toLowerCase();
      } else if (rawDisplayName.isNotEmpty) {
        fullName = rawDisplayName;
      }

      // 2. Query Neon Tech directly (authoritative source)
      Map<String, dynamic>? neonUser;
      try {
        neonUser = await _neonDb.getUserByEmail(cleanEmail);
      } catch (e) {
        debugPrint("⚠️ Direct Neon DB email query error: $e");
      }

      if (neonUser == null) {
        try {
          neonUser = await _neonDb.getUserByUid(firebaseUser.uid);
        } catch (e) {
          debugPrint("⚠️ Direct Neon DB UID query error: $e");
        }
      }

      // 3. Check backend API if direct Neon DB didn't find the user
      if (neonUser == null) {
        try {
          final res = await _apiClient.post('/auth/login', {
            'email': cleanEmail,
            'password': password,
          });
          if (res.success && res.data != null) {
            final data = res.data;
            final user = data['user'] ?? {};
            role = data['role'] ?? user['role'] ?? role;
            neonId = data['neonId']?.toString() ?? user['id']?.toString() ?? neonId;
            fullName = user['full_name'] ?? fullName;
          }
        } catch (e) {
          debugPrint("⚠️ Backend API sync query error: $e");
        }
      }

      if (neonUser != null) {
        role = neonUser['role']?.toString().toLowerCase() ?? role;
        neonId = neonUser['id']?.toString() ?? neonId;
        fullName = neonUser['full_name']?.toString() ?? fullName;
      }

      // If user exists in neither Neon DB nor backend, auto-sync this Firebase user into Neon Tech
      if (neonUser == null && (role == null || role.isEmpty)) {
        debugPrint("🔄 Auto-syncing Firebase user $cleanEmail into Neon Tech DB...");
        role = cleanEmail.contains('anchor') ? 'anchor' : 'organizer';
        neonId = await _neonDb.saveUser(
          firebaseUid: firebaseUser.uid,
          email: cleanEmail,
          fullName: fullName,
          role: role,
        );
      }

      role ??= cleanEmail.contains('anchor') ? 'anchor' : 'organizer';

      // 4. Ensure Firebase user has role and Neon UUID stored in displayName
      final targetDisplayName = "$fullName|${neonId ?? ''}|$role";
      if (rawDisplayName != targetDisplayName) {
        try {
          await firebaseUser.updateDisplayName(targetDisplayName);
          debugPrint("✅ Synced role ($role) and Neon UUID ($neonId) into Firebase user displayName: $targetDisplayName");
        } catch (_) {}
      }

      _currentAppUser = AppUser(
        uid: firebaseUser.uid,
        email: cleanEmail,
        fullName: fullName,
        role: role,
        neonId: neonId,
      );

      return _currentAppUser!;
    } catch (e) {
      if (_isConfigError(e) || (e is FirebaseAuthException && (e.code == 'user-not-found' || e.code == 'invalid-credential'))) {
        debugPrint("⚠️ Attempting resilient Neon DB login for $cleanEmail...");
        return await _fallbackLogin(cleanEmail, password);
      } else if (e is FirebaseAuthException) {
        throw _translateFirebaseError(e);
      } else {
        return await _fallbackLogin(cleanEmail, password);
      }
    }
  }

  /// Resilient fallback login using Neon Tech DB directly
  Future<AppUser> _fallbackLogin(String cleanEmail, String password) async {
    try {
      // 1. Try direct Neon Tech DB lookup
      final neonUser = await _neonDb.getUserByEmail(cleanEmail);
      if (neonUser != null) {
        final role = neonUser['role']?.toString().toLowerCase() ?? 'organizer';
        final neonId = neonUser['id']?.toString();
        final firebaseUid = neonUser['firebase_uid']?.toString() ?? 'local_${const Uuid().v4()}';
        final fullName = neonUser['full_name']?.toString() ?? cleanEmail.split('@').first;

        _currentAppUser = AppUser(
          uid: firebaseUid,
          email: cleanEmail,
          fullName: fullName,
          role: role,
          neonId: neonId,
          isFallback: true,
        );
        debugPrint("✅ Resilient login succeeded via direct Neon Tech DB. Role: $role, Neon UUID: $neonId");
        return _currentAppUser!;
      }

      // 2. Try backend API fallback
      final response = await _apiClient.post('/auth/login', {
        'email': cleanEmail,
        'password': password,
      });

      if (response.success && response.data != null) {
        final data = response.data;
        final user = data['user'] ?? {};
        final role = data['role'] ?? user['role'] ?? 'organizer';
        final neonId = data['neonId']?.toString() ?? user['id']?.toString();
        final firebaseUid = data['firebaseUid']?.toString() ?? user['firebase_uid']?.toString() ?? 'local_${const Uuid().v4()}';
        final fullName = user['full_name'] ?? cleanEmail.split('@').first;

        _currentAppUser = AppUser(
          uid: firebaseUid,
          email: cleanEmail,
          fullName: fullName,
          role: role,
          neonId: neonId,
          isFallback: true,
        );
        debugPrint("✅ Resilient login succeeded via backend API. Role: $role, Neon UUID: $neonId");
        return _currentAppUser!;
      } else {
        throw Exception(response.errorMessage ?? "No account found for $cleanEmail. Please register first.");
      }
    } catch (err) {
      debugPrint("⚠️ Fallback login error: $err");
      throw Exception(err.toString().replaceAll("Exception: ", ""));
    }
  }

  /// One-Tap Quick Demo Login for instant testing
  Future<AppUser> demoLogin(String role) async {
    if (role.toLowerCase() == 'anchor') {
      _currentAppUser = AppUser(
        uid: 'user-anchor-1',
        email: 'jordan@stageflow.io',
        fullName: 'Jordan Hayes',
        role: 'anchor',
        neonId: 'demo-anchor-jordan',
      );
    } else {
      _currentAppUser = AppUser(
        uid: 'user-organizer-1',
        email: 'alex@technova.io',
        fullName: 'Alex Rivera',
        role: 'organizer',
        neonId: 'demo-organizer-alex',
      );
    }
    return _currentAppUser!;
  }

  /// Send Password Reset Email
  Future<void> sendPasswordResetEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw Exception('Please enter a valid email address.');
    }

    try {
      await _auth.sendPasswordResetEmail(email: cleanEmail);
      debugPrint("📧 Password reset email dispatched via Firebase to $cleanEmail");
    } catch (e) {
      if (_isConfigError(e)) {
        debugPrint("⚠️ Firebase Auth config missing. Simulated password reset email sent to $cleanEmail");
        // Fallback simulation for offline/demo environment
        return;
      } else if (e is FirebaseAuthException) {
        throw Exception(_translateFirebaseError(e));
      } else {
        debugPrint("⚠️ Password reset fallback: $e");
      }
    }
  }

  Future<void> saveSession(AppUser user) async {
    _currentAppUser = user;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('user_uid', user.uid);
      await prefs.setString('user_email', user.email);
      await prefs.setString('user_fullname', user.fullName);
      await prefs.setString('user_role', user.role);
      if (user.neonId != null) {
        await prefs.setString('user_neon_id', user.neonId!);
      }
      debugPrint("💾 Saved user session: ${user.email} (${user.role})");
    } catch (e) {
      debugPrint("⚠️ Could not save session: $e");
    }
  }

  Future<AppUser?> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      if (!isLoggedIn) return null;

      final uid = prefs.getString('user_uid');
      final email = prefs.getString('user_email');
      final fullName = prefs.getString('user_fullname');
      final role = prefs.getString('user_role');
      final neonId = prefs.getString('user_neon_id');

      if (uid != null && email != null && role != null) {
        _currentAppUser = AppUser(
          uid: uid,
          email: email,
          fullName: fullName ?? email.split('@').first,
          role: role,
          neonId: neonId,
        );
        debugPrint("⚡ Restored active user session: $email ($role)");
        return _currentAppUser;
      }
    } catch (e) {
      debugPrint("⚠️ Could not restore session: $e");
    }
    return null;
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {}
    await _clearPersistedSession();
    _currentAppUser = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      debugPrint("🚪 User session cleared.");
    } catch (_) {}
  }

  /// Format raw Firebase exceptions into clear, actionable, user-friendly messages
  String _translateFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email address is already registered. Please log in instead.';
      case 'invalid-email':
        return 'Please provide a valid email address.';
      case 'weak-password':
        return 'The password is too weak. Please use at least 8 characters.';
      case 'user-not-found':
        return 'No account found with this email address. Please register first.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again in a few moments.';
      case 'network-request-failed':
        return 'Network connection error. Please check your internet connection.';
      default:
        if (e.message != null && e.message!.contains('CONFIGURATION_NOT_FOUND')) {
          return 'Firebase Authentication is not yet enabled in Firebase Console. Please enable Email/Password provider.';
        }
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
