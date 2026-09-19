import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:postgres/postgres.dart';

/// Direct, cloud-native connection service to Neon PostgreSQL database.
/// This runs directly from the Flutter app on any physical device or emulator,
/// ensuring data is ALWAYS stored in Neon Tech even without a local backend running.
class NeonDatabaseService {
  static final NeonDatabaseService _instance = NeonDatabaseService._internal();
  factory NeonDatabaseService() => _instance;
  NeonDatabaseService._internal();

  static const String _host = 'ep-lingering-river-b48n0foj.c-6.us-east-2.aws.neon.tech';
  static const String _database = 'neondb';
  static const String _username = 'neondb_owner';
  static const String _password = 'npg_OAEhqtznw7D8';
  static const int _port = 5432;

  Future<Connection> _getConnection() async {
    final endpoint = Endpoint(
      host: _host,
      database: _database,
      username: _username,
      password: _password,
      port: _port,
    );

    return await Connection.open(
      endpoint,
      settings: const ConnectionSettings(
        sslMode: SslMode.require,
        connectTimeout: Duration(seconds: 10),
      ),
    );
  }

  /// Save or synchronize user profile directly into Neon PostgreSQL
  /// Returns the persistent Neon UUID (`id`)
  Future<String?> saveUser({
    required String firebaseUid,
    required String email,
    required String fullName,
    required String role,
    String? phoneNumber,
    String? bio,
    String? profileImageUrl,
    Map<String, dynamic>? profileData,
  }) async {
    Connection? connection;
    try {
      connection = await _getConnection();
      final cleanEmail = email.trim().toLowerCase();
      final cleanName = fullName.trim();
      final cleanRole = role.trim().toLowerCase();
      final jsonProfileData = jsonEncode(profileData ?? {});

      const sql = """
        INSERT INTO users (
          firebase_uid,
          email,
          full_name,
          role,
          phone_number,
          bio,
          profile_image_url,
          profile_data,
          updated_at
        ) VALUES (
          \$1,
          \$2,
          \$3,
          CAST(\$4 AS user_role),
          \$5,
          \$6,
          \$7,
          CAST(\$8 AS jsonb),
          CURRENT_TIMESTAMP
        )
        ON CONFLICT (email) DO UPDATE SET
          firebase_uid = EXCLUDED.firebase_uid,
          full_name = EXCLUDED.full_name,
          role = EXCLUDED.role,
          phone_number = COALESCE(EXCLUDED.phone_number, users.phone_number),
          bio = COALESCE(EXCLUDED.bio, users.bio),
          profile_image_url = COALESCE(EXCLUDED.profile_image_url, users.profile_image_url),
          profile_data = EXCLUDED.profile_data,
          updated_at = CURRENT_TIMESTAMP
        RETURNING id;
      """;

      final result = await connection.execute(
        Sql.indexed(sql),
        parameters: [
          firebaseUid,
          cleanEmail,
          cleanName,
          cleanRole,
          phoneNumber,
          bio,
          profileImageUrl,
          jsonProfileData,
        ],
      );

      if (result.isNotEmpty) {
        final neonId = result.first[0]?.toString();
        debugPrint("🐘 [Neon DB Direct] User saved successfully. Neon UUID: \$neonId");
        return neonId;
      }
      return null;
    } catch (e) {
      debugPrint("⚠️ [Neon DB Direct] Error saving user: \$e");
      return null;
    } finally {
      await connection?.close();
    }
  }

  /// Query user profile directly from Neon PostgreSQL by email
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    Connection? connection;
    try {
      connection = await _getConnection();
      final cleanEmail = email.trim().toLowerCase();

      final result = await connection.execute(
        Sql.indexed("SELECT id, firebase_uid, email, full_name, role FROM users WHERE LOWER(email) = \$1 LIMIT 1"),
        parameters: [cleanEmail],
      );

      if (result.isNotEmpty) {
        final row = result.first;
        return {
          'id': row[0]?.toString(),
          'firebase_uid': row[1]?.toString(),
          'email': row[2]?.toString(),
          'full_name': row[3]?.toString(),
          'role': row[4]?.toString(),
        };
      }
      return null;
    } catch (e) {
      debugPrint("⚠️ [Neon DB Direct] Error fetching user by email: \$e");
      return null;
    } finally {
      await connection?.close();
    }
  }

  /// Query user profile directly from Neon PostgreSQL by Firebase UID
  Future<Map<String, dynamic>?> getUserByUid(String uid) async {
    Connection? connection;
    try {
      connection = await _getConnection();
      final result = await connection.execute(
        Sql.indexed("SELECT id, firebase_uid, email, full_name, role FROM users WHERE firebase_uid = \$1 LIMIT 1"),
        parameters: [uid],
      );

      if (result.isNotEmpty) {
        final row = result.first;
        return {
          'id': row[0]?.toString(),
          'firebase_uid': row[1]?.toString(),
          'email': row[2]?.toString(),
          'full_name': row[3]?.toString(),
          'role': row[4]?.toString(),
        };
      }
      return null;
    } catch (e) {
      debugPrint("⚠️ [Neon DB Direct] Error fetching user by UID: \$e");
      return null;
    } finally {
      await connection?.close();
    }
  }
}
