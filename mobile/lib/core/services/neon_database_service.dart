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
      debugPrint("⚠️ [Neon DB Direct] Error fetching user by UID: $e");
      return null;
    } finally {
      await connection?.close();
    }
  }

  /// Save or update an event directly in Neon PostgreSQL over TLS
  Future<String?> saveEvent(EventModel event) async {
    Connection? connection;
    try {
      connection = await _getConnection();

      // Ensure a valid user UUID exists for created_by FK
      String? creatorUuid;
      final currentAppUser = AuthService().currentAppUser;
      if (_isUuid(currentAppUser?.neonId)) {
        creatorUuid = currentAppUser!.neonId;
      } else {
        final userResult = await connection.execute(
          Sql.named("SELECT id FROM users LIMIT 1"),
        );
        if (userResult.isNotEmpty) {
          creatorUuid = userResult.first[0]?.toString();
        } else {
          creatorUuid = await saveUser(
            firebaseUid: 'system_organizer_default',
            email: 'organizer@smart-eve.io',
            fullName: 'SmartEve Organizer',
            role: 'organizer',
          );
        }
      }

      final startDate = DateTime.tryParse(event.date) ?? DateTime.now();
      final endDate = startDate.add(const Duration(hours: 8));

      // Map UI event category to Neon ENUM
      String mappedType = 'seminar';
      final lowerType = event.type.toLowerCase();
      if (lowerType.contains('hack')) {
        mappedType = 'hackathon';
      } else if (lowerType.contains('work')) {
        mappedType = 'workshop';
      } else if (lowerType.contains('cultur')) {
        mappedType = 'cultural_program';
      } else if (lowerType.contains('award') || lowerType.contains('comp')) {
        mappedType = 'competition';
      }

      // Map UI status to Neon ENUM
      String mappedStatus = 'draft';
      final lowerStatus = event.liveState.status.toLowerCase();
      if (lowerStatus == 'live') {
        mappedStatus = 'live';
      } else if (lowerStatus == 'published') {
        mappedStatus = 'scheduled';
      } else if (lowerStatus == 'completed') {
        mappedStatus = 'completed';
      }

      final isPublished = event.liveState.status == 'published' || event.liveState.status == 'live';

      if (_isUuid(event.id)) {
        const updateSql = """
          UPDATE events SET
            title = @title,
            description = @description,
            event_type = CAST(@event_type AS event_type),
            start_date = @start_date,
            end_date = @end_date,
            location = @location,
            status = CAST(@status AS event_status),
            is_published = @is_published,
            updated_at = CURRENT_TIMESTAMP
          WHERE id = CAST(@id AS uuid)
          RETURNING id;
        """;

        final updateResult = await connection.execute(
          Sql.named(updateSql),
          parameters: {
            'id': event.id,
            'title': event.name,
            'description': "${event.description}\n[Tone: ${event.tone} | Code: ${event.joinCode}]",
            'event_type': mappedType,
            'start_date': startDate.toUtc(),
            'end_date': endDate.toUtc(),
            'location': event.venue,
            'status': mappedStatus,
            'is_published': isPublished,
          },
        );

        if (updateResult.isNotEmpty) {
          final updatedId = updateResult.first[0]?.toString();
          debugPrint("🐘 [Neon DB Direct] Event '${event.name}' updated in Neon DB. UUID: $updatedId");
          return updatedId;
        }
      }

      const sql = """
        INSERT INTO events (
          title,
          description,
          event_type,
          start_date,
          end_date,
          location,
          created_by,
          status,
          is_published,
          updated_at
        ) VALUES (
          @title,
          @description,
          CAST(@event_type AS event_type),
          @start_date,
          @end_date,
          @location,
          CAST(@created_by AS uuid),
          CAST(@status AS event_status),
          @is_published,
          CURRENT_TIMESTAMP
        )
        RETURNING id;
      """;

      final result = await connection.execute(
        Sql.named(sql),
        parameters: {
          'title': event.name,
          'description': "${event.description}\n[Tone: ${event.tone} | Code: ${event.joinCode}]",
          'event_type': mappedType,
          'start_date': startDate.toUtc(),
          'end_date': endDate.toUtc(),
          'location': event.venue,
          'created_by': creatorUuid,
          'status': mappedStatus,
          'is_published': isPublished,
        },
      );

      if (result.isNotEmpty) {
        final neonEventId = result.first[0]?.toString();
        debugPrint("🐘 [Neon DB Direct] Event '${event.name}' saved directly to Neon DB. UUID: $neonEventId");
        return neonEventId;
      }
      return null;
    } catch (e) {
      debugPrint("⚠️ [Neon DB Direct] Error saving event: $e");
      return null;
    } finally {
      await connection?.close();
    }
  }

  /// Fetch all events directly from Neon PostgreSQL
  Future<List<EventModel>> getEvents() async {
    Connection? connection;
    final List<EventModel> eventsList = [];
    try {
      connection = await _getConnection();
      const sql = """
        SELECT 
          id, 
          title, 
          description, 
          event_type, 
          start_date, 
          location, 
          created_by, 
          status, 
          is_published, 
          created_at 
        FROM events 
        ORDER BY created_at DESC;
      """;

      final result = await connection.execute(Sql.named(sql));
      for (final row in result) {
        final id = row[0]?.toString() ?? '';
        final title = row[1]?.toString() ?? 'Untitled Event';
        final rawDesc = row[2]?.toString() ?? '';
        final rawType = row[3]?.toString() ?? 'Conference';
        final rawStartDate = row[4];
        String startDateStr = '';
        if (rawStartDate != null) {
          if (rawStartDate is DateTime) {
            final dt = rawStartDate.toLocal();
            final y = dt.year.toString().padLeft(4, '0');
            final m = dt.month.toString().padLeft(2, '0');
            final d = dt.day.toString().padLeft(2, '0');
            startDateStr = '$y-$m-$d';
          } else {
            final dt = DateTime.tryParse(rawStartDate.toString())?.toLocal();
            if (dt != null) {
              final y = dt.year.toString().padLeft(4, '0');
              final m = dt.month.toString().padLeft(2, '0');
              final d = dt.day.toString().padLeft(2, '0');
              startDateStr = '$y-$m-$d';
            } else {
              startDateStr = rawStartDate.toString().split('T').first.split(' ').first;
            }
          }
        } else {
          startDateStr = DateTime.now().toString().split(' ')[0];
        }

        final venue = row[5]?.toString() ?? 'Main Auditorium';
        final ownerId = row[6]?.toString() ?? '';
        final rawStatus = row[7]?.toString() ?? 'draft';

        // Extract tone and joinCode if present in description format
        String tone = 'Visionary & Energetic';
        String joinCode = 'TN26';
        if (rawDesc.contains('[Tone:') && rawDesc.contains('Code:')) {
          final codeMatch = RegExp(r'Code:\s*([A-Z0-9]+)').firstMatch(rawDesc);
          if (codeMatch != null) joinCode = codeMatch.group(1)!;
          final toneMatch = RegExp(r'Tone:\s*([^|\]]+)').firstMatch(rawDesc);
          if (toneMatch != null) tone = toneMatch.group(1)!.trim();
        } else {
          joinCode = id.length >= 4 ? id.substring(0, 4).toUpperCase() : 'EVT1';
        }

        String uiStatus = 'draft';
        if (rawStatus == 'live') {
          uiStatus = 'live';
        } else if (rawStatus == 'scheduled' || rawStatus == 'published') {
          uiStatus = 'published';
        }

        int createdAtMillis = DateTime.now().millisecondsSinceEpoch;
        if (row.length > 9 && row[9] != null) {
          if (row[9] is DateTime) {
            createdAtMillis = (row[9] as DateTime).millisecondsSinceEpoch;
          } else {
            createdAtMillis = DateTime.tryParse(row[9].toString())?.millisecondsSinceEpoch ?? createdAtMillis;
          }
        }

        eventsList.add(
          EventModel(
            id: id,
            name: title,
            type: rawType.toUpperCase(),
            date: startDateStr,
            venue: venue,
            tone: tone,
            description: rawDesc.split('\n[').first.trim(),
            ownerId: ownerId,
            joinCode: joinCode,
            liveState: LiveStateModel(status: uiStatus),
            createdAt: createdAtMillis,
          ),
        );
      }
      debugPrint("🐘 [Neon DB Direct] Fetched ${eventsList.length} events directly from Neon DB.");
    } catch (e) {
      debugPrint("⚠️ [Neon DB Direct] Error fetching events: $e");
    } finally {
      await connection?.close();
    }
    return eventsList;
  }

  /// Save or update a speaker directly in Neon PostgreSQL over TLS
  Future<String?> saveSpeaker(SpeakerModel speaker, {String? targetEventId}) async {
    Connection? connection;
    try {
      connection = await _getConnection();
      await _ensureSpeakersTable(connection);

      String? eventUuid;
      if (_isUuid(targetEventId)) {
        eventUuid = targetEventId;
      } else {
        final eventResult = await connection.execute(
          Sql.named("SELECT id FROM events ORDER BY created_at DESC LIMIT 1"),
        );
        if (eventResult.isNotEmpty) {
          eventUuid = eventResult.first[0]?.toString();
        }
      }

      if (eventUuid == null) {
        debugPrint("⚠️ Cannot save speaker without an event UUID in Neon DB.");
        return null;
      }

      // Check if updating an existing speaker with a valid Neon UUID
      if (_isUuid(speaker.id)) {
        const updateSql = """
          UPDATE speakers SET
            name = @name,
            designation = @designation,
            organization = @organization,
            expertise_area = @topic,
            bio = @bio,
            profile_image_url = @photo_url,
            updated_at = CURRENT_TIMESTAMP
          WHERE id = CAST(@id AS uuid)
          RETURNING id;
        """;

        final updateResult = await connection.execute(
          Sql.named(updateSql),
          parameters: {
            'id': speaker.id,
            'name': speaker.name,
            'designation': speaker.designation,
            'organization': speaker.organization,
            'topic': speaker.topic,
            'bio': speaker.bio,
            'photo_url': speaker.photoUrl ?? '',
          },
        );

        if (updateResult.isNotEmpty) {
          final updatedId = updateResult.first[0]?.toString();
          debugPrint("🐘 [Neon DB Direct] Speaker '${speaker.name}' updated in Neon DB. UUID: $updatedId");
          return updatedId;
        }
      }

      // Otherwise, perform INSERT for a new speaker
      const insertSql = """
        INSERT INTO speakers (
          event_id,
          name,
          designation,
          organization,
          expertise_area,
          bio,
          profile_image_url,
          updated_at
        ) VALUES (
          CAST(@event_id AS uuid),
          @name,
          @designation,
          @organization,
          @topic,
          @bio,
          @photo_url,
          CURRENT_TIMESTAMP
        )
        RETURNING id;
      """;

      final result = await connection.execute(
        Sql.named(insertSql),
        parameters: {
          'event_id': eventUuid,
          'name': speaker.name,
          'designation': speaker.designation,
          'organization': speaker.organization,
          'topic': speaker.topic,
          'bio': speaker.bio,
          'photo_url': speaker.photoUrl ?? '',
        },
      );

      if (result.isNotEmpty) {
        final speakerId = result.first[0]?.toString();
        debugPrint("🐘 [Neon DB Direct] Speaker '${speaker.name}' inserted into Neon DB. UUID: $speakerId");
        return speakerId;
      }
      return null;
    } catch (e) {
      debugPrint("⚠️ [Neon DB Direct] Error saving speaker: $e");
      return null;
    } finally {
      await connection?.close();
    }
  }

  /// Fetch all speakers for an event directly from Neon PostgreSQL
  Future<List<SpeakerModel>> getSpeakersForEvent(String? targetEventId) async {
    Connection? connection;
    final List<SpeakerModel> speakersList = [];
    try {
      connection = await _getConnection();
      await _ensureSpeakersTable(connection);

      String sql = """
        SELECT 
          id, 
          name, 
          designation, 
          organization, 
          expertise_area, 
          bio, 
          profile_image_url 
        FROM speakers 
      """;

      if (_isUuid(targetEventId)) {
        sql += " WHERE event_id = CAST(@event_id AS uuid) ";
      }
      sql += " ORDER BY created_at ASC; ";

      final result = await connection.execute(
        Sql.named(sql),
        parameters: _isUuid(targetEventId) ? {'event_id': targetEventId} : {},
      );

      for (final row in result) {
        final id = row[0]?.toString() ?? '';
        final name = row[1]?.toString() ?? 'Speaker';
        final designation = row[2]?.toString() ?? '';
        final organization = row[3]?.toString() ?? '';
        final topic = row[4]?.toString() ?? '';
        final bio = row[5]?.toString() ?? '';
        final photoUrl = row[6]?.toString();

        speakersList.add(
          SpeakerModel(
            id: id,
            name: name,
            designation: designation,
            organization: organization,
            topic: topic,
            bio: bio,
            photoUrl: photoUrl?.isNotEmpty == true ? photoUrl : null,
            status: 'arrived',
          ),
        );
      }
      debugPrint("🐘 [Neon DB Direct] Fetched ${speakersList.length} speakers from Neon DB.");
    } catch (e) {
      debugPrint("⚠️ [Neon DB Direct] Error fetching speakers: $e");
    } finally {
      await connection?.close();
    }
    return speakersList;
  }

  /// Delete speaker directly from Neon PostgreSQL
  Future<bool> deleteSpeaker(String speakerId) async {
    Connection? connection;
    try {
      connection = await _getConnection();
      if (_isUuid(speakerId)) {
        await connection.execute(
          Sql.named("DELETE FROM speakers WHERE id = CAST(@id AS uuid)"),
          parameters: {'id': speakerId},
        );
      }
      debugPrint("🐘 [Neon DB Direct] Speaker $speakerId deleted from Neon DB.");
      return true;
    } catch (e) {
      debugPrint("⚠️ [Neon DB Direct] Error deleting speaker: $e");
      return false;
    } finally {
      await connection?.close();
    }
  }

  /// Ensure agenda_items table and all required columns exist in Neon PostgreSQL
  Future<void> _ensureAgendaTable(Connection connection) async {
    try {
      const createSql = """
        CREATE TABLE IF NOT EXISTS agenda_items (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          event_id UUID REFERENCES events(id) ON DELETE CASCADE,
          title VARCHAR(255) NOT NULL,
          item_type VARCHAR(50) DEFAULT 'talk',
          duration_minutes INTEGER DEFAULT 15,
          planned_start TIMESTAMP WITH TIME ZONE,
          start_time TIMESTAMP WITH TIME ZONE,
          end_time TIMESTAMP WITH TIME ZONE,
          status VARCHAR(50) DEFAULT 'upcoming',
          is_absorbable BOOLEAN DEFAULT FALSE,
          min_duration_minutes INTEGER,
          hard_start BOOLEAN DEFAULT FALSE,
          notes TEXT,
          order_index INTEGER DEFAULT 0,
          speaker_ids JSONB DEFAULT '[]'::jsonb,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
      """;
      await connection.execute(Sql.named(createSql));

      const alterSql = """
        ALTER TABLE agenda_items ADD COLUMN IF NOT EXISTS item_type VARCHAR(50) DEFAULT 'talk';
        ALTER TABLE agenda_items ADD COLUMN IF NOT EXISTS duration_minutes INTEGER DEFAULT 15;
        ALTER TABLE agenda_items ADD COLUMN IF NOT EXISTS planned_start TIMESTAMP WITH TIME ZONE;
        ALTER TABLE agenda_items ADD COLUMN IF NOT EXISTS start_time TIMESTAMP WITH TIME ZONE;
        ALTER TABLE agenda_items ADD COLUMN IF NOT EXISTS end_time TIMESTAMP WITH TIME ZONE;
        ALTER TABLE agenda_items ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'upcoming';
        ALTER TABLE agenda_items ADD COLUMN IF NOT EXISTS is_absorbable BOOLEAN DEFAULT FALSE;
        ALTER TABLE agenda_items ADD COLUMN IF NOT EXISTS min_duration_minutes INTEGER;
        ALTER TABLE agenda_items ADD COLUMN IF NOT EXISTS hard_start BOOLEAN DEFAULT FALSE;
        ALTER TABLE agenda_items ADD COLUMN IF NOT EXISTS notes TEXT;
        ALTER TABLE agenda_items ADD COLUMN IF NOT EXISTS order_index INTEGER DEFAULT 0;
        ALTER TABLE agenda_items ADD COLUMN IF NOT EXISTS speaker_ids JSONB DEFAULT '[]'::jsonb;
      """;
      await connection.execute(Sql.named(alterSql));
    } catch (e) {
      debugPrint("⚠️ [Neon DB Direct] Error checking/updating agenda_items columns: $e");
    }
  }

  /// Save or update an agenda item in Neon PostgreSQL
  Future<String?> saveAgendaItem(dynamic item, {String? targetEventId}) async {
    Connection? connection;
    try {
      connection = await _getConnection();
      await _ensureAgendaTable(connection);

      String? eventUuid;
      if (_isUuid(targetEventId)) {
        eventUuid = targetEventId;
      } else {
        final eventResult = await connection.execute(
          Sql.named("SELECT id FROM events ORDER BY created_at DESC LIMIT 1"),
        );
        if (eventResult.isNotEmpty) {
          eventUuid = eventResult.first[0]?.toString();
        }
      }

      if (eventUuid == null) {
        debugPrint("⚠️ Cannot save agenda item without an event UUID in Neon DB.");
        return null;
      }

      final jsonSpeakers = jsonEncode(item.speakerIds ?? []);
      DateTime? plannedStartDt = DateTime.tryParse(item.plannedStart);
      DateTime? startTimeDt = DateTime.tryParse(item.startTime);
      DateTime? endTimeDt = DateTime.tryParse(item.endTime);

      if (_isUuid(item.id)) {
        const updateSql = """
          UPDATE agenda_items SET
            title = @title,
            item_type = @type,
            duration_minutes = @duration,
            planned_start = @planned_start,
            start_time = @start_time,
            end_time = @end_time,
            status = @status,
            is_absorbable = @absorbable,
            min_duration_minutes = @min_duration,
            hard_start = @hard_start,
            notes = @notes,
            order_index = @order_index,
            speaker_ids = CAST(@speaker_ids AS jsonb),
            updated_at = CURRENT_TIMESTAMP
          WHERE id = CAST(@id AS uuid)
          RETURNING id;
        """;

        final updateResult = await connection.execute(
          Sql.named(updateSql),
          parameters: {
            'id': item.id,
            'title': item.title,
            'type': item.type,
            'duration': item.duration,
            'planned_start': plannedStartDt?.toUtc(),
            'start_time': startTimeDt?.toUtc(),
            'end_time': endTimeDt?.toUtc(),
            'status': item.status,
            'absorbable': item.absorbable,
            'min_duration': item.minDuration,
            'hard_start': item.hardStart,
            'notes': item.notes ?? '',
            'order_index': item.order,
            'speaker_ids': jsonSpeakers,
          },
        );

        if (updateResult.isNotEmpty) {
          final updatedId = updateResult.first[0]?.toString();
          debugPrint("🐘 [Neon DB Direct] Agenda item '${item.title}' updated in Neon DB. UUID: $updatedId");
          return updatedId;
        }
      }

      const insertSql = """
        INSERT INTO agenda_items (
          event_id,
          title,
          item_type,
          duration_minutes,
          planned_start,
          start_time,
          end_time,
          status,
          is_absorbable,
          min_duration_minutes,
          hard_start,
          notes,
          order_index,
          speaker_ids,
          updated_at
        ) VALUES (
          CAST(@event_id AS uuid),
          @title,
          @type,
          @duration,
          @planned_start,
          @start_time,
          @end_time,
          @status,
          @absorbable,
          @min_duration,
          @hard_start,
          @notes,
          @order_index,
          CAST(@speaker_ids AS jsonb),
          CURRENT_TIMESTAMP
        )
        RETURNING id;
      """;

      final result = await connection.execute(
        Sql.named(insertSql),
        parameters: {
          'event_id': eventUuid,
          'title': item.title,
          'type': item.type,
          'duration': item.duration,
          'planned_start': plannedStartDt?.toUtc(),
          'start_time': startTimeDt?.toUtc(),
          'end_time': endTimeDt?.toUtc(),
          'status': item.status,
          'absorbable': item.absorbable,
          'min_duration': item.minDuration,
          'hard_start': item.hardStart,
          'notes': item.notes ?? '',
          'order_index': item.order,
          'speaker_ids': jsonSpeakers,
        },
      );

      if (result.isNotEmpty) {
        final agendaId = result.first[0]?.toString();
        debugPrint("🐘 [Neon DB Direct] Agenda item '${item.title}' inserted into Neon DB. UUID: $agendaId");
        return agendaId;
      }
      return null;
    } catch (e) {
      debugPrint("⚠️ [Neon DB Direct] Error saving agenda item: $e");
      return null;
    } finally {
      await connection?.close();
    }
  }

  /// Fetch agenda items for an event directly from Neon PostgreSQL
  Future<List<Map<String, dynamic>>> getAgendaForEvent(String? targetEventId) async {
    Connection? connection;
    final List<Map<String, dynamic>> agendaList = [];
    try {
      connection = await _getConnection();
      await _ensureAgendaTable(connection);

      String sql = """
        SELECT 
          id, 
          title, 
          item_type, 
          duration_minutes, 
          planned_start, 
          start_time, 
          end_time, 
          status, 
          is_absorbable, 
          min_duration_minutes, 
          hard_start, 
          notes, 
          order_index, 
          speaker_ids 
        FROM agenda_items 
      """;

      if (_isUuid(targetEventId)) {
        sql += " WHERE event_id = CAST(@event_id AS uuid) ";
      }
      sql += " ORDER BY order_index ASC, created_at ASC; ";

      final result = await connection.execute(
        Sql.named(sql),
        parameters: _isUuid(targetEventId) ? {'event_id': targetEventId} : {},
      );

      for (final row in result) {
        List<String> speakers = [];
        if (row[13] != null) {
          try {
            final raw = row[13];
            if (raw is List) {
              speakers = raw.map((e) => e.toString()).toList();
            } else if (raw is String) {
              final parsed = jsonDecode(raw);
              if (parsed is List) speakers = parsed.map((e) => e.toString()).toList();
            }
          } catch (_) {}
        }

        String formatIso(dynamic cell) {
          if (cell == null) return '';
          if (cell is DateTime) return cell.toLocal().toIso8601String();
          final dt = DateTime.tryParse(cell.toString());
          return dt != null ? dt.toLocal().toIso8601String() : cell.toString();
        }

        agendaList.add({
          'id': row[0]?.toString() ?? '',
          'title': row[1]?.toString() ?? 'Session',
          'type': row[2]?.toString() ?? 'talk',
          'duration': (row[3] as num?)?.toInt() ?? 15,
          'plannedStart': formatIso(row[4]),
          'startTime': formatIso(row[5]),
          'endTime': formatIso(row[6]),
          'status': row[7]?.toString() ?? 'upcoming',
          'absorbable': row[8] == true,
          'minDuration': (row[9] as num?)?.toInt(),
          'hardStart': row[10] == true,
          'notes': row[11]?.toString() ?? '',
          'order': (row[12] as num?)?.toInt() ?? 0,
          'speakerIds': speakers,
        });
      }
      debugPrint("🐘 [Neon DB Direct] Fetched ${agendaList.length} agenda items from Neon DB.");
    } catch (e) {
      debugPrint("⚠️ [Neon DB Direct] Error fetching agenda: $e");
    } finally {
      await connection?.close();
    }
    return agendaList;
  }

  /// Delete agenda item directly from Neon PostgreSQL
  Future<bool> deleteAgendaItem(String itemId) async {
    Connection? connection;
    try {
      connection = await _getConnection();
      if (_isUuid(itemId)) {
        await connection.execute(
          Sql.named("DELETE FROM agenda_items WHERE id = CAST(@id AS uuid)"),
          parameters: {'id': itemId},
        );
      }
      debugPrint("🐘 [Neon DB Direct] Agenda item $itemId deleted from Neon DB.");
      return true;
    } catch (e) {
      debugPrint("⚠️ [Neon DB Direct] Error deleting agenda item: $e");
      return false;
    } finally {
      await connection?.close();
    }
  }

  /// Update event live status directly in Neon PostgreSQL
  Future<bool> updateEventStatus(String eventId, String status) async {
    Connection? connection;
    try {
      connection = await _getConnection();
      if (_isUuid(eventId)) {
        String mappedStatus = 'draft';
        if (status == 'live') mappedStatus = 'live';
        if (status == 'published') mappedStatus = 'scheduled';
        if (status == 'completed') mappedStatus = 'completed';

        await connection.execute(
          Sql.named("UPDATE events SET status = CAST(@status AS event_status), updated_at = CURRENT_TIMESTAMP WHERE id = CAST(@id AS uuid)"),
          parameters: {'id': eventId, 'status': mappedStatus},
        );
        debugPrint("🐘 [Neon DB Direct] Event $eventId status updated to $status.");
      }
      return true;
    } catch (e) {
      debugPrint("⚠️ [Neon DB Direct] Error updating event status: $e");
      return false;
    } finally {
      await connection?.close();
    }
  }

  /// Batch update recalculated agenda timings and statuses in Neon PostgreSQL
  Future<bool> updateAgendaTimingsBatch(List<dynamic> items, {String? targetEventId}) async {
    Connection? connection;
    try {
      connection = await _getConnection();
      await _ensureAgendaTable(connection);

      for (final item in items) {
        if (_isUuid(item.id.toString())) {
          DateTime? plannedStartDt = DateTime.tryParse(item.plannedStart ?? '');
          DateTime? startTimeDt = DateTime.tryParse(item.startTime ?? '');
          DateTime? endTimeDt = DateTime.tryParse(item.endTime ?? '');

          await connection.execute(
            Sql.named("""
              UPDATE agenda_items SET
                duration_minutes = @duration,
                planned_start = @planned_start,
                start_time = @start_time,
                end_time = @end_time,
                status = @status,
                order_index = @order_index,
                updated_at = CURRENT_TIMESTAMP
              WHERE id = CAST(@id AS uuid)
            """),
            parameters: {
              'id': item.id,
              'duration': item.duration,
              'planned_start': plannedStartDt?.toUtc(),
              'start_time': startTimeDt?.toUtc(),
              'end_time': endTimeDt?.toUtc(),
              'status': item.status,
              'order_index': item.order,
            },
          );
        }
      }
      debugPrint("🐘 [Neon DB Direct] Batch updated ${items.length} agenda item timings in Neon DB.");
      return true;
    } catch (e) {
      debugPrint("⚠️ [Neon DB Direct] Error batch updating agenda timings: $e");
      return false;
    } finally {
      await connection?.close();
    }
  }

  /// Ensure qna_questions table exists in Neon PostgreSQL
  Future<void> _ensureQnaTable(Connection connection) async {
    try {
      const createSql = """
        CREATE TABLE IF NOT EXISTS qna_questions (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          event_id UUID REFERENCES events(id) ON DELETE CASCADE,
          session_id UUID,
          author_name VARCHAR(255) DEFAULT 'Anonymous Attendee',
          question TEXT NOT NULL,
          upvotes INTEGER DEFAULT 0,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
      """;
      await connection.execute(Sql.named(createSql));
    } catch (e) {
      debugPrint("⚠️ [Neon DB Direct] Error checking/updating qna_questions table: $e");
    }
  }

  /// Submit a live Q&A question from an attendee into Neon PostgreSQL
  Future<bool> saveQnaQuestion({
    required String eventId,
    required String authorName,
    required String question,
    String? sessionId,
  }) async {
    Connection? connection;
    try {
      connection = await _getConnection();
      await _ensureQnaTable(connection);

      String? targetEventUuid;
      if (_isUuid(eventId)) {
        targetEventUuid = eventId;
      } else {
        final res = await connection.execute(Sql.named("SELECT id FROM events ORDER BY created_at DESC LIMIT 1"));
        if (res.isNotEmpty) targetEventUuid = res.first[0]?.toString();
      }

      if (targetEventUuid == null) return false;

      final sql = """
        INSERT INTO qna_questions (
          event_id,
          session_id,
          author_name,
          question,
          created_at
        ) VALUES (
          CAST(@event_id AS uuid),
          ${sessionId != null && _isUuid(sessionId) ? "CAST(@session_id AS uuid)" : "NULL"},
          @author_name,
          @question,
          CURRENT_TIMESTAMP
        );
      """;

      await connection.execute(
        Sql.named(sql),
        parameters: {
          'event_id': targetEventUuid,
          if (sessionId != null && _isUuid(sessionId)) 'session_id': sessionId,
          'author_name': authorName,
          'question': question,
        },
      );
      debugPrint("🐘 [Neon DB Direct] Saved Q&A question: '$question'");
      return true;
    } catch (e) {
      debugPrint("⚠️ [Neon DB Direct] Error saving Q&A question: $e");
      return false;
    } finally {
      await connection?.close();
    }
  }

  /// Fetch live Q&A questions for an event from Neon PostgreSQL
  Future<List<Map<String, dynamic>>> getQnaQuestions(String? eventId) async {
    Connection? connection;
    final List<Map<String, dynamic>> questions = [];
    try {
      connection = await _getConnection();
      await _ensureQnaTable(connection);

      String sql = "SELECT id, author_name, question, upvotes, created_at FROM qna_questions ";
      if (_isUuid(eventId)) {
        sql += " WHERE event_id = CAST(@event_id AS uuid) ";
      }
      sql += " ORDER BY created_at DESC LIMIT 30; ";

      final result = await connection.execute(
        Sql.named(sql),
        parameters: _isUuid(eventId) ? {'event_id': eventId} : {},
      );

      for (final row in result) {
        questions.add({
          'id': row[0]?.toString() ?? '',
          'authorName': row[1]?.toString() ?? 'Attendee',
          'question': row[2]?.toString() ?? '',
          'upvotes': (row[3] as num?)?.toInt() ?? 0,
          'createdAt': row[4]?.toString() ?? '',
        });
      }
    } catch (e) {
      debugPrint("⚠️ [Neon DB Direct] Error fetching Q&A questions: $e");
    } finally {
      await connection?.close();
    }
    return questions;
  }
}

