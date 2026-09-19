import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../network/api_client.dart';
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

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ApiClient _apiClient = ApiClient();
  final NeonDatabaseService _neonDb = NeonDatabaseService();

  AppUser? _currentAppUser;
  AppUser? get currentAppUser => _currentAppUser;
  String get currentUserRole => _currentAppUser?.role ?? 'organizer';
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

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
    if (credential != null && credential.user != null && neonId != null) {
      try {
        final displayNameWithNeon = "$cleanName|$neonId";
        await credential.user!.updateDisplayName(displayNameWithNeon);
        debugPrint("✅ [3/3] Saved Neon UUID ($neonId) into Firebase user displayName: $displayNameWithNeon");
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
    if (credential != null && credential.user != null && neonId != null) {
      try {
        final displayNameWithNeon = "$cleanName|$neonId";
        await credential.user!.updateDisplayName(displayNameWithNeon);
        debugPrint("✅ [3/3] Saved Neon UUID ($neonId) into Firebase user displayName: $displayNameWithNeon");
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
      String role = 'organizer';
      String fullName = cleanEmail.split('@').first;

      // Extract existing Neon UUID from displayName if present
      final rawDisplayName = firebaseUser.displayName ?? '';
      if (rawDisplayName.contains('|')) {
        final parts = rawDisplayName.split('|');
        fullName = parts[0];
        neonId = parts.length > 1 ? parts[1] : null;
      } else if (rawDisplayName.isNotEmpty) {
        fullName = rawDisplayName;
      }

      // 2. Query Neon Tech directly
      Map<String, dynamic>? neonUser;
      try {
        neonUser = await _neonDb.getUserByEmail(cleanEmail);
      } catch (_) {}

      // If missing in Neon Tech, auto-sync this Firebase user into Neon Tech right now!
      if (neonUser == null) {
        debugPrint("🔄 Auto-syncing Firebase user $cleanEmail into Neon Tech DB...");
        role = cleanEmail.contains('anchor') ? 'anchor' : 'organizer';
        neonId = await _neonDb.saveUser(
          firebaseUid: firebaseUser.uid,
          email: cleanEmail,
          fullName: fullName,
          role: role,
        );
      } else {
        role = neonUser['role']?.toString().toLowerCase() ?? 'organizer';
        neonId = neonUser['id']?.toString();
        fullName = neonUser['full_name']?.toString() ?? fullName;
      }

      // 3. Ensure Firebase user has Neon UUID saved in displayName
      if (neonId != null && !rawDisplayName.contains('|')) {
        try {
          await firebaseUser.updateDisplayName("$fullName|$neonId");
          debugPrint("✅ Synced Neon UUID ($neonId) into Firebase user displayName");
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

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {}
    _currentAppUser = null;
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
