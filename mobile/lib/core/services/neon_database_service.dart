import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:postgres/postgres.dart';
import 'auth_service.dart';
import '../../models/event_model.dart';
import '../../models/speaker_model.dart';

/// Direct, cloud-native connection service to Neon PostgreSQL database.
/// Runs directly from the Flutter app over TLS, ensuring data is ALWAYS
/// stored in Neon PostgreSQL even without a local backend running.
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

  bool _isUuid(String? str) {
    if (str == null || str.trim().isEmpty) return false;
    return RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(str.trim());
  }

  /// Ensure speakers table and columns exist in Neon PostgreSQL
  Future<void> _ensureSpeakersTable(Connection connection) async {
    try {
      const createSql = """
        CREATE TABLE IF NOT EXISTS speakers (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          event_id UUID REFERENCES events(id) ON DELETE CASCADE,
          name VARCHAR(255) NOT NULL,
          designation VARCHAR(255),
          organization VARCHAR(255),
          expertise_area VARCHAR(255),
          bio TEXT,
          profile_image_url TEXT,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
      """;
      await connection.execute(Sql.named(createSql));

      const alterSql = """
        ALTER TABLE speakers ADD COLUMN IF NOT EXISTS designation VARCHAR(255);
        ALTER TABLE speakers ADD COLUMN IF NOT EXISTS organization VARCHAR(255);
        ALTER TABLE speakers ADD COLUMN IF NOT EXISTS expertise_area VARCHAR(255);
        ALTER TABLE speakers ADD COLUMN IF NOT EXISTS bio TEXT;
        ALTER TABLE speakers ADD COLUMN IF NOT EXISTS profile_image_url TEXT;
      """;
      await connection.execute(Sql.named(alterSql));
    } catch (e) {
      debugPrint("⚠️ [Neon DB Direct] Error checking/updating speakers table: $e");
    }
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
          @firebase_uid,
          @email,
          @full_name,
          CAST(@role AS user_role),
          @phone_number,
          @bio,
          @profile_image_url,
          CAST(@profile_data AS jsonb),
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
        Sql.named(sql),
        parameters: {
          'firebase_uid': firebaseUid,
          'email': cleanEmail,
          'full_name': cleanName,
          'role': cleanRole,
          'phone_number': phoneNumber,
          'bio': bio,
          'profile_image_url': profileImageUrl,
          'profile_data': jsonProfileData,
        },
      );

      if (result.isNotEmpty) {
        final neonId = result.first[0]?.toString();
        debugPrint("🐘 [Neon DB Direct] User saved successfully. Neon UUID: $neonId");
        return neonId;
      }
      return null;
    } catch (e) {
      debugPrint("⚠️ [Neon DB Direct] Error saving user: $e");
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
        Sql.named("SELECT id, firebase_uid, email, full_name, role FROM users WHERE LOWER(email) = @email LIMIT 1"),
        parameters: {'email': cleanEmail},
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
      debugPrint("⚠️ [Neon DB Direct] Error fetching user by email: $e");
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
        Sql.named("SELECT id, firebase_uid, email, full_name, role FROM users WHERE firebase_uid = @uid LIMIT 1"),
        parameters: {'uid': uid},
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
