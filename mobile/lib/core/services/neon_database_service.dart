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
      debugPrint("⚠️ [Neon DB Direct] Error fetching user by UID: $e");
      return null;
    } finally {
      await connection?.close();
    }
  }

  /// Query real Anchor Dashboard data directly from Neon PostgreSQL
  Future<Map<String, dynamic>> getAnchorDashboardData([String? anchorId]) async {
    Connection? connection;
    try {
      connection = await _getConnection();
      final result = await connection.execute(Sql.indexed("""
        SELECT 
          ea.id as assignment_id,
          ea.status as anchor_status,
          ea.invited_at,
          e.id as event_id,
          e.title,
          e.description,
          e.event_type,
          e.status as event_status,
          e.start_date,
          e.end_date,
          e.location,
          u.full_name as organizer_name,
          u.college_name as organizer_college,
          u.phone_number as organizer_phone
        FROM event_anchors ea
        JOIN events e ON ea.event_id = e.id
        LEFT JOIN users u ON e.created_by = u.id
        WHERE e.deleted_at IS NULL
        ORDER BY ea.invited_at DESC
      """));

      final List<Map<String, dynamic>> invitations = [];
      final List<Map<String, dynamic>> upcoming = [];
      final List<Map<String, dynamic>> completed = [];

      for (final row in result) {
        final assignmentId = row[0]?.toString() ?? '';
        final anchorStatus = row[1]?.toString() ?? 'invited';
        final invitedAt = row[2]?.toString() ?? '';
        final eventId = row[3]?.toString() ?? '';
        final title = row[4]?.toString() ?? 'SmartEve Conference';
        final description = row[5]?.toString() ?? '';
        final eventType = row[6]?.toString() ?? 'Conference';
        final eventStatus = row[7]?.toString() ?? 'scheduled';
        final startDate = row[8] != null ? DateTime.tryParse(row[8].toString()) ?? DateTime.now() : DateTime.now();
        final endDate = row[9] != null ? DateTime.tryParse(row[9].toString()) ?? DateTime.now().add(const Duration(hours: 4)) : DateTime.now().add(const Duration(hours: 4));
        final venue = row[10]?.toString() ?? 'Main Stage & Auditorium';
        final organizerName = row[11]?.toString() ?? 'Romal Tandel';
        final collegeName = row[12]?.toString() ?? 'SmartEve Partner Arena';

        final item = {
          'id': eventId,
          'assignmentId': assignmentId,
          'eventId': eventId,
          'title': title,
          'eventType': eventType,
          'organizerName': organizerName,
          'collegeName': collegeName,
          'date': "${startDate.day}/${startDate.month}/${startDate.year}",
          'time': "${startDate.hour.toString().padLeft(2, '0')}:${startDate.minute.toString().padLeft(2, '0')}",
          'invitedAt': invitedAt,
          'venue': venue,
          'description': description,
          'status': (eventStatus == 'live' || anchorStatus == 'active') ? 'active' : (eventStatus == 'completed' ? 'completed' : 'accepted'),
          'joinCode': '${title.replaceAll(RegExp(r'[^a-zA-Z]'), '').padRight(2, 'E').substring(0, 2).toUpperCase()}26',
          'duration': '${endDate.difference(startDate).inHours.clamp(1, 12)}h 00m',
        };

        if (anchorStatus == 'invited') {
          invitations.add(item);
        } else if (eventStatus == 'completed' || anchorStatus == 'completed') {
          completed.add(item);
        } else {
          upcoming.add(item);
        }
      }

      return {
        'invitations': invitations,
        'upcomingEvents': upcoming,
        'completedEvents': completed,
        'unreadAiAlertCount': 1,
      };
    } catch (e) {
      debugPrint("⚠️ [Neon DB Direct] Error fetching anchor dashboard: $e");
      return {};
    } finally {
      await connection?.close();
    }
  }

  /// Update Anchor Invitation Status directly in Neon PostgreSQL
  Future<bool> updateInvitationStatus(String assignmentOrEventId, String status) async {
    Connection? connection;
    try {
      connection = await _getConnection();
      await connection.execute(
        Sql.indexed("""
          UPDATE event_anchors 
          SET status = \$1, accepted_at = CURRENT_TIMESTAMP 
          WHERE id::text = \$2 OR event_id::text = \$2
        """),
        parameters: [status, assignmentOrEventId],
      );
      return true;
    } catch (e) {
      debugPrint("⚠️ [Neon DB Direct] Error updating invitation status: $e");
      return false;
    } finally {
      await connection?.close();
    }
  }

  /// Fetch Event Details directly from Neon PostgreSQL
  Future<Map<String, dynamic>?> getEventDetails(String eventId) async {
    Connection? connection;
    try {
      connection = await _getConnection();
      final result = await connection.execute(
        Sql.indexed("""
          SELECT e.id, e.title, e.description, e.event_type, e.status, e.start_date, e.end_date, e.location,
                 u.full_name as organizer_name, u.phone as organizer_phone, u.email as organizer_email, u.avatar_url as organizer_avatar
          FROM events e
          LEFT JOIN users u ON e.created_by = u.id
          WHERE (e.id::text = \$1 OR e.id = \$1::uuid) AND e.deleted_at IS NULL
          LIMIT 1
        """),
        parameters: [eventId],
      );
      if (result.isNotEmpty) {
        final row = result.first;
        return {
          'id': row[0]?.toString(),
          'title': row[1]?.toString(),
          'description': row[2]?.toString(),
          'eventType': row[3]?.toString(),
          'status': row[4]?.toString(),
          'startDate': row[5]?.toString(),
          'endDate': row[6]?.toString(),
          'location': row[7]?.toString(),
          'organizerName': row[8]?.toString() ?? 'Romal Tandel',
          'organizerPhone': row[9]?.toString() ?? '+91 98765 43210',
          'organizerEmail': row[10]?.toString() ?? 'romaltandel1264@gmail.com',
          'organizerAvatar': row[11]?.toString(),
        };
      }
      return null;
    } catch (e) {
      debugPrint("⚠️ [Neon DB Direct] Error fetching event details: $e");
      return null;
    } finally {
      await connection?.close();
    }
  }

  /// Fetch Agenda Items directly from Neon PostgreSQL
  Future<List<Map<String, dynamic>>> getAgendaItems(String eventId) async {
    Connection? connection;
    try {
      connection = await _getConnection();
      final result = await connection.execute(
        Sql.indexed("""
          SELECT a.id, a.title, a.description, a.type, a.speaker_id, a.start_time, a.end_time,
                 a.duration_minutes, a.order_in_agenda, a.status, a.notes,
                 s.name as speaker_name, s.designation as speaker_designation,
                 s.organization as speaker_company, s.profile_image_url as speaker_avatar
          FROM agenda_items a
          LEFT JOIN speakers s ON a.speaker_id = s.id
          WHERE a.event_id::text = \$1 OR a.event_id = \$1::uuid
          ORDER BY a.order_in_agenda ASC
        """),
        parameters: [eventId],
      );

      final List<Map<String, dynamic>> items = [];
      for (final r in result) {
        final startIso = r[5]?.toString() ?? DateTime.now().toIso8601String();
        final endIso = r[6]?.toString() ?? DateTime.now().add(const Duration(minutes: 15)).toIso8601String();
        final duration = int.tryParse(r[7]?.toString() ?? '') ?? 15;
        final rawStatus = r[9]?.toString() ?? 'scheduled';
        final status = rawStatus == 'in_progress' ? 'live' : (rawStatus == 'completed' ? 'done' : 'upcoming');

        items.add({
          'id': r[0]?.toString(),
          'title': r[1]?.toString() ?? 'Session',
          'description': r[2]?.toString() ?? '',
          'type': r[3]?.toString() ?? 'talk',
          'speakerIds': r[4] != null ? [r[4].toString()] : <String>[],
          'duration': duration,
          'plannedStart': startIso,
          'startTime': startIso,
          'endTime': endIso,
          'status': status,
          'order': int.tryParse(r[8]?.toString() ?? '') ?? 1,
          'notes': r[10]?.toString(),
          'speakerName': r[11]?.toString(),
          'speakerDesignation': r[12]?.toString(),
          'speakerCompany': r[13]?.toString(),
          'speakerAvatar': r[14]?.toString(),
        });
      }
      return items;
    } catch (e) {
      debugPrint("⚠️ [Neon DB Direct] Error fetching agenda items: $e");
      return [];
    } finally {
      await connection?.close();
    }
  }

  /// Fetch Speakers directly from Neon PostgreSQL
  Future<List<Map<String, dynamic>>> getSpeakers(String eventId) async {
    Connection? connection;
    try {
      connection = await _getConnection();
      final result = await connection.execute(
        Sql.indexed("""
          SELECT id, name, designation, organization, bio, profile_image_url, order_in_event
          FROM speakers
          WHERE event_id::text = \$1 OR event_id = \$1::uuid
          ORDER BY order_in_event ASC
        """),
        parameters: [eventId],
      );

      return result.map((r) => {
        'id': r[0]?.toString() ?? '',
        'name': r[1]?.toString() ?? 'Speaker',
        'designation': r[2]?.toString() ?? 'Keynote Speaker',
        'organization': r[3]?.toString() ?? 'BliXo Tech',
        'topic': r[4]?.toString() ?? 'Tech Presentation',
        'bio': r[4]?.toString() ?? '',
        'photoUrl': r[5]?.toString(),
        'status': 'arrived',
      }).toList();
    } catch (e) {
      debugPrint("⚠️ [Neon DB Direct] Error fetching speakers: $e");
      return [];
    } finally {
      await connection?.close();
    }
  }

  /// Fetch AI Scripts directly from Neon PostgreSQL
  Future<List<Map<String, dynamic>>> getAiScripts(String eventId) async {
    Connection? connection;
    try {
      connection = await _getConnection();
      final result = await connection.execute(
        Sql.indexed("""
          SELECT id, agenda_item_id, script_type, title, content, version, is_approved, tone, target_audience
          FROM ai_scripts
          WHERE event_id::text = \$1 OR event_id = \$1::uuid
          ORDER BY created_at ASC
        """),
        parameters: [eventId],
      );

      return result.map((r) => {
        'id': r[0]?.toString() ?? '',
        'itemId': r[1]?.toString(),
        'type': r[2]?.toString() ?? 'opening',
        'title': r[3]?.toString() ?? 'Stage Script',
        'text': r[4]?.toString() ?? '',
        'version': int.tryParse(r[5]?.toString() ?? '') ?? 1,
        'status': r[6] == true ? 'approved' : 'pending',
        'tone': r[7]?.toString() ?? 'Motivational',
        'targetAudience': r[8]?.toString() ?? 'All Attendees',
        'source': 'ai',
        'provider': 'gemini',
      }).toList();
    } catch (e) {
      debugPrint("⚠️ [Neon DB Direct] Error fetching ai_scripts: $e");
      return [];
    } finally {
      await connection?.close();
    }
  }

  /// Record Delay directly in Neon PostgreSQL
  Future<bool> delayAgendaItem(String eventId, String? itemId, int delayMinutes, String? reason) async {
    Connection? connection;
    try {
      connection = await _getConnection();
      if (itemId != null) {
        await connection.execute(
          Sql.indexed("""
            UPDATE agenda_items 
            SET duration_minutes = duration_minutes + \$1, status = 'delayed'
            WHERE (id::text = \$2 OR id = \$2::uuid) AND (event_id::text = \$3 OR event_id = \$3::uuid)
          """),
          parameters: [delayMinutes, itemId, eventId],
        );
      }
      return true;
    } catch (e) {
      debugPrint("⚠️ [Neon DB Direct] Error delaying agenda item: $e");
      return false;
    } finally {
      await connection?.close();
    }
  }

  /// Complete Agenda Item directly in Neon PostgreSQL
  Future<bool> completeAgendaItem(String eventId, String itemId) async {
    Connection? connection;
    try {
      connection = await _getConnection();
      await connection.execute(
        Sql.indexed("""
          UPDATE agenda_items 
          SET status = 'completed', actual_end_time = CURRENT_TIMESTAMP
          WHERE (id::text = \$1 OR id = \$1::uuid) AND (event_id::text = \$2 OR event_id = \$2::uuid)
        """),
        parameters: [itemId, eventId],
      );
      return true;
    } catch (e) {
      debugPrint("⚠️ [Neon DB Direct] Error completing agenda item: $e");
      return false;
    } finally {
      await connection?.close();
    }
  }
}
