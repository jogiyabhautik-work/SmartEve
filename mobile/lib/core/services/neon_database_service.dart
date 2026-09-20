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

  /// Ensure a valid event UUID is available.
  /// If [targetEventId] is already a UUID, return it.
  /// Otherwise, lookup the latest event UUID in Neon DB.
  /// If no events exist in Neon DB, auto-provision a default Event and return its UUID.
  Future<String?> _getOrProvisionEventUuid(Connection connection, String? targetEventId) async {
    if (_isUuid(targetEventId)) {
      return targetEventId;
    }

    try {
      final eventResult = await connection.execute(
        Sql.named("SELECT id FROM events ORDER BY created_at DESC LIMIT 1"),
      );
      if (eventResult.isNotEmpty) {
        final foundId = eventResult.first[0]?.toString();
        if (_isUuid(foundId)) return foundId;
      }

      // No event found in Neon DB! Auto-provision a default main stage event.
      debugPrint("ℹ️ [Neon DB Direct] No active event found in Neon DB. Auto-provisioning default event...");

      String? creatorUuid;
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

      const insertSql = """
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
          'SmartEve Main Stage Summit',
          'Official Stage Summit [Tone: Visionary & Energetic | Code: TS26]',
          CAST('seminar' AS event_type),
          CURRENT_TIMESTAMP,
          CURRENT_TIMESTAMP + INTERVAL '8 hours',
          'Grand Auditorium',
          CAST(@created_by AS uuid),
          CAST('live' AS event_status),
          TRUE,
          CURRENT_TIMESTAMP
        )
        RETURNING id;
      """;

      final newEventResult = await connection.execute(
        Sql.named(insertSql),
        parameters: {'created_by': creatorUuid},
      );

      if (newEventResult.isNotEmpty) {
        final provisionedId = newEventResult.first[0]?.toString();
        debugPrint("🐘 [Neon DB Direct] Auto-provisioned Default Event. UUID: $provisionedId");
        return provisionedId;
      }
    } catch (e) {
      debugPrint("⚠️ [Neon DB Direct] Error provisioning default event UUID: $e");
    }

    return null;
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
        ALTER TABLE speakers 
          ADD COLUMN IF NOT EXISTS designation VARCHAR(255),
          ADD COLUMN IF NOT EXISTS organization VARCHAR(255),
          ADD COLUMN IF NOT EXISTS expertise_area VARCHAR(255),
          ADD COLUMN IF NOT EXISTS bio TEXT,
          ADD COLUMN IF NOT EXISTS profile_image_url TEXT;
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
        Sql.named("SELECT id, firebase_uid, email, full_name, CAST(role AS text) FROM users WHERE LOWER(email) = @email LIMIT 1"),
        parameters: {'email': cleanEmail},
      );

      if (result.isNotEmpty) {
        final row = result.first;
        return {
          'id': _safeString(row[0]),
          'firebase_uid': _safeString(row[1]),
          'email': _safeString(row[2]),
          'full_name': _safeString(row[3]),
          'role': _safeString(row[4]),
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
        Sql.named("SELECT id, firebase_uid, email, full_name, CAST(role AS text) FROM users WHERE firebase_uid = @uid LIMIT 1"),
        parameters: {'uid': uid},
      );

      if (result.isNotEmpty) {
        final row = result.first;
        return {
          'id': _safeString(row[0]),
          'firebase_uid': _safeString(row[1]),
          'email': _safeString(row[2]),
          'full_name': _safeString(row[3]),
          'role': _safeString(row[4]),
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
  String _safeString(dynamic val, [String fallback = '']) {
    if (val == null) return fallback;
    final str = val.toString();
    if (str.toLowerCase().contains('undecodedbytes') || str.toLowerCase().contains('instance of')) {
      return fallback;
    }
    return str;
  }

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
        final id = _safeString(row[0]);
        final title = _safeString(row[1], 'Untitled Event');
        final rawDesc = _safeString(row[2]);
        final rawType = _safeString(row[3], 'Conference');
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
              startDateStr = _safeString(rawStartDate).split('T').first.split(' ').first;
            }
          }
        } else {
          startDateStr = DateTime.now().toString().split(' ')[0];
        }

        final venue = _safeString(row[5], 'Main Auditorium');
        final ownerId = _safeString(row[6]);
        final rawStatus = _safeString(row[7], 'draft');

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

      if (eventsList.isEmpty) {
        debugPrint("ℹ️ [Neon DB Direct] No events in DB. Provisioning initial default event...");
        await _getOrProvisionEventUuid(connection, null);
        final retryResult = await connection.execute(Sql.named(sql));
        for (final row in retryResult) {
          final id = _safeString(row[0]);
          final title = _safeString(row[1], 'Untitled Event');
          final rawDesc = _safeString(row[2]);
          final rawType = _safeString(row[3], 'Conference');
          final venue = _safeString(row[5], 'Main Auditorium');
          final ownerId = _safeString(row[6]);
          eventsList.add(
            EventModel(
              id: id,
              name: title,
              type: rawType.toUpperCase(),
              date: DateTime.now().toString().split(' ')[0],
              venue: venue,
              tone: 'Visionary & Energetic',
              description: rawDesc.split('\n[').first.trim(),
              ownerId: ownerId,
              joinCode: id.length >= 4 ? id.substring(0, 4).toUpperCase() : 'TS26',
              liveState: LiveStateModel(status: 'live'),
              createdAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );
        }
      }
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

      final eventUuid = await _getOrProvisionEventUuid(connection, targetEventId);

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

      var result = await connection.execute(
        Sql.named(sql),
        parameters: _isUuid(targetEventId) ? {'event_id': targetEventId} : {},
      );

      // Fallback: If targeted search by eventId returned no speakers, fetch all speakers in DB
      if (result.isEmpty && _isUuid(targetEventId)) {
        const fallbackSql = "SELECT id, name, designation, organization, expertise_area, bio, profile_image_url FROM speakers ORDER BY created_at ASC;";
        result = await connection.execute(Sql.named(fallbackSql));
      }

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

      final alterStatements = [
        "ALTER TABLE agenda_items ADD COLUMN IF NOT EXISTS item_type VARCHAR(50) DEFAULT 'talk';",
        "ALTER TABLE agenda_items ADD COLUMN IF NOT EXISTS duration_minutes INTEGER DEFAULT 15;",
        "ALTER TABLE agenda_items ADD COLUMN IF NOT EXISTS planned_start TIMESTAMP WITH TIME ZONE;",
        "ALTER TABLE agenda_items ADD COLUMN IF NOT EXISTS start_time TIMESTAMP WITH TIME ZONE;",
        "ALTER TABLE agenda_items ADD COLUMN IF NOT EXISTS end_time TIMESTAMP WITH TIME ZONE;",
        "ALTER TABLE agenda_items ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'upcoming';",
        "ALTER TABLE agenda_items ADD COLUMN IF NOT EXISTS is_absorbable BOOLEAN DEFAULT FALSE;",
        "ALTER TABLE agenda_items ADD COLUMN IF NOT EXISTS min_duration_minutes INTEGER;",
        "ALTER TABLE agenda_items ADD COLUMN IF NOT EXISTS hard_start BOOLEAN DEFAULT FALSE;",
        "ALTER TABLE agenda_items ADD COLUMN IF NOT EXISTS notes TEXT;",
        "ALTER TABLE agenda_items ADD COLUMN IF NOT EXISTS order_index INTEGER DEFAULT 0;",
        "ALTER TABLE agenda_items ADD COLUMN IF NOT EXISTS speaker_ids JSONB DEFAULT '[]'::jsonb;",
      ];
      for (final stmt in alterStatements) {
        try {
          await connection.execute(Sql.named(stmt));
        } catch (_) {}
      }
    } catch (e) {
      debugPrint("⚠️ [Neon DB Direct] Error checking/updating agenda_items columns: $e");
    }
  }

  String _dbAgendaStatus(String? status) {
    final s = (status ?? '').toLowerCase();
    if (s == 'live' || s == 'in_progress' || s == 'ongoing') return 'in_progress';
    if (s == 'done' || s == 'completed') return 'completed';
    if (s == 'skipped') return 'skipped';
    return 'upcoming';
  }

  String _uiAgendaStatus(String? status) {
    final s = (status ?? '').toLowerCase();
    if (s == 'in_progress' || s == 'ongoing' || s == 'live') return 'live';
    if (s == 'completed' || s == 'done') return 'done';
    if (s == 'skipped') return 'skipped';
    return 'upcoming';
  }

  /// Auto-seed default stage agenda items into Neon DB when database is fresh/empty
  Future<void> _seedDefaultAgendaItems(Connection connection, String eventUuid) async {
    try {
      final now = DateTime.now().toUtc();
      final defaultItems = [
        {
          'title': 'Welcome & Opening Remarks',
          'type': 'keynote',
          'duration': 15,
          'planned_start': now,
          'start_time': now,
          'end_time': now.add(const Duration(minutes: 15)),
          'status': 'in_progress',
          'order': 1,
          'notes': 'Stage opening remarks and event introduction',
        },
        {
          'title': 'Keynote Technical Deep-Dive',
          'type': 'talk',
          'duration': 45,
          'planned_start': now.add(const Duration(minutes: 15)),
          'start_time': now.add(const Duration(minutes: 15)),
          'end_time': now.add(const Duration(minutes: 60)),
          'status': 'upcoming',
          'order': 2,
          'notes': 'Featured technical presentation',
        },
        {
          'title': 'Interactive Q&A & Stage Wrap-Up',
          'type': 'panel',
          'duration': 20,
          'planned_start': now.add(const Duration(minutes: 60)),
          'start_time': now.add(const Duration(minutes: 60)),
          'end_time': now.add(const Duration(minutes: 80)),
          'status': 'upcoming',
          'order': 3,
          'notes': 'Audience Q&A and stage wrap-up',
        },
      ];

      for (final item in defaultItems) {
        await connection.execute(
          Sql.named("""
            INSERT INTO agenda_items (
              event_id,
              title,
              item_type,
              duration_minutes,
              planned_start,
              start_time,
              end_time,
              status,
              order_index,
              notes,
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
              @order,
              @notes,
              CURRENT_TIMESTAMP
            );
          """),
          parameters: {
            'event_id': eventUuid,
            'title': item['title'],
            'type': item['type'],
            'duration': item['duration'],
            'planned_start': item['planned_start'],
            'start_time': item['start_time'],
            'end_time': item['end_time'],
            'status': _dbAgendaStatus(item['status'] as String?),
            'order': item['order'],
            'notes': item['notes'],
          },
        );
      }
      debugPrint("🐘 [Neon DB Direct] Auto-seeded default stage agenda into Neon DB.");
    } catch (e) {
      debugPrint("⚠️ [Neon DB Direct] Error auto-seeding default agenda items: $e");
    }
  }

  /// Save or update an agenda item in Neon PostgreSQL
  Future<String?> saveAgendaItem(dynamic item, {String? targetEventId}) async {
    Connection? connection;
    try {
      connection = await _getConnection();
      await _ensureAgendaTable(connection);

      final eventUuid = await _getOrProvisionEventUuid(connection, targetEventId);

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
            'status': _dbAgendaStatus(item.status?.toString()),
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
          'status': _dbAgendaStatus(item.status?.toString()),
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

      var result = await connection.execute(
        Sql.named(sql),
        parameters: _isUuid(targetEventId) ? {'event_id': targetEventId} : {},
      );

      // Fallback: If targeted search by eventId returned no agenda items, fetch all agenda items in DB
      if (result.isEmpty && _isUuid(targetEventId)) {
        const fallbackSql = "SELECT id, title, item_type, duration_minutes, planned_start, start_time, end_time, status, is_absorbable, min_duration_minutes, hard_start, notes, order_index, speaker_ids FROM agenda_items ORDER BY order_index ASC, created_at ASC;";
        result = await connection.execute(Sql.named(fallbackSql));
      }

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
          'status': _uiAgendaStatus(row[7]?.toString()),
          'absorbable': row[8] == true,
          'minDuration': (row[9] as num?)?.toInt(),
          'hardStart': row[10] == true,
          'notes': row[11]?.toString() ?? '',
          'order': (row[12] as num?)?.toInt() ?? 0,
          'speakerIds': speakers,
        });
      }
      debugPrint("🐘 [Neon DB Direct] Fetched ${agendaList.length} agenda items from Neon DB.");

      if (agendaList.isEmpty) {
        debugPrint("ℹ️ [Neon DB Direct] 0 agenda items found in DB. Auto-seeding default stage agenda into Neon DB...");
        final eventUuid = await _getOrProvisionEventUuid(connection, targetEventId);
        if (eventUuid != null) {
          await _seedDefaultAgendaItems(connection, eventUuid);
          var retryResult = await connection.execute(
            Sql.named(sql),
            parameters: _isUuid(targetEventId) ? {'event_id': targetEventId} : {},
          );
          if (retryResult.isEmpty && _isUuid(targetEventId)) {
            const fallbackSql = "SELECT id, title, item_type, duration_minutes, planned_start, start_time, end_time, status, is_absorbable, min_duration_minutes, hard_start, notes, order_index, speaker_ids FROM agenda_items ORDER BY order_index ASC, created_at ASC;";
            retryResult = await connection.execute(Sql.named(fallbackSql));
          }

          agendaList.clear();
          for (final row in retryResult) {
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
              'status': _uiAgendaStatus(row[7]?.toString()),
              'absorbable': row[8] == true,
              'minDuration': (row[9] as num?)?.toInt(),
              'hardStart': row[10] == true,
              'notes': row[11]?.toString() ?? '',
              'order': (row[12] as num?)?.toInt() ?? 0,
              'speakerIds': speakers,
            });
          }
        }
      }
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
              'status': _dbAgendaStatus(item.status?.toString()),
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

      final targetEventUuid = await _getOrProvisionEventUuid(connection, eventId);

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

  /// Ensure stage_notifications table exists in Neon PostgreSQL
  Future<void> _ensureNotificationsTable(Connection connection) async {
    try {
      const createSql = """
        CREATE TABLE IF NOT EXISTS stage_notifications (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          event_id UUID REFERENCES events(id) ON DELETE CASCADE,
          notif_type VARCHAR(50) DEFAULT 'announcement',
          message TEXT NOT NULL,
          created_by VARCHAR(100) DEFAULT 'organizer',
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
      """;
      await connection.execute(Sql.named(createSql));
    } catch (e) {
      debugPrint("⚠️ [Neon DB Direct] Error checking/updating stage_notifications table: $e");
    }
  }

  /// Broadcast a live stage notification / announcement into Neon PostgreSQL
  Future<bool> saveNotification({
    required String eventId,
    required String message,
    String type = 'announcement',
    String createdBy = 'organizer',
  }) async {
    Connection? connection;
    try {
      connection = await _getConnection();
      await _ensureNotificationsTable(connection);

      final targetEventUuid = await _getOrProvisionEventUuid(connection, eventId);

      if (targetEventUuid == null) return false;

      const sql = """
        INSERT INTO stage_notifications (
          event_id,
          notif_type,
          message,
          created_by,
          created_at
        ) VALUES (
          CAST(@event_id AS uuid),
          @notif_type,
          @message,
          @created_by,
          CURRENT_TIMESTAMP
        );
      """;

      await connection.execute(
        Sql.named(sql),
        parameters: {
          'event_id': targetEventUuid,
          'notif_type': type,
          'message': message,
          'created_by': createdBy,
        },
      );
      debugPrint("🐘 [Neon DB Direct] Saved stage notification: '$message'");
      return true;
    } catch (e) {
      debugPrint("⚠️ [Neon DB Direct] Error saving stage notification: $e");
      return false;
    } finally {
      await connection?.close();
    }
  }

  /// Fetch live stage notifications for an event from Neon PostgreSQL
  Future<List<Map<String, dynamic>>> getNotifications(String? eventId) async {
    Connection? connection;
    final List<Map<String, dynamic>> notifs = [];
    try {
      connection = await _getConnection();
      await _ensureNotificationsTable(connection);

      String sql = "SELECT id, notif_type, message, created_by, created_at FROM stage_notifications ";
      if (_isUuid(eventId)) {
        sql += " WHERE event_id = CAST(@event_id AS uuid) ";
      }
      sql += " ORDER BY created_at DESC LIMIT 20; ";

      final result = await connection.execute(
        Sql.named(sql),
        parameters: _isUuid(eventId) ? {'event_id': eventId} : {},
      );

      for (final row in result) {
        int createdAtMillis = DateTime.now().millisecondsSinceEpoch;
        if (row[4] != null) {
          if (row[4] is DateTime) {
            createdAtMillis = (row[4] as DateTime).millisecondsSinceEpoch;
          } else {
            createdAtMillis = DateTime.tryParse(row[4].toString())?.millisecondsSinceEpoch ?? createdAtMillis;
          }
        }

        notifs.add({
          'id': row[0]?.toString() ?? '',
          'type': row[1]?.toString() ?? 'announcement',
          'message': row[2]?.toString() ?? '',
          'createdBy': row[3]?.toString() ?? 'organizer',
          'createdAt': createdAtMillis,
        });
      }
    } catch (e) {
      debugPrint("⚠️ [Neon DB Direct] Error fetching stage notifications: $e");
    } finally {
      await connection?.close();
    }
    return notifs;
  }

  /// Ensure event_anchors table exists in Neon PostgreSQL
  Future<void> _ensureEventAnchorsTable(Connection connection) async {
    try {
      const createSql = """
        CREATE TABLE IF NOT EXISTS event_anchors (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          event_id UUID REFERENCES events(id) ON DELETE CASCADE,
          anchor_id UUID,
          anchor_email VARCHAR(255),
          invitation_status VARCHAR(50) DEFAULT 'pending',
          notes TEXT,
          pay_offer VARCHAR(100),
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
      """;
      await connection.execute(Sql.named(createSql));
    } catch (e) {
      debugPrint("⚠️ [Neon DB Direct] Error checking/creating event_anchors table: $e");
    }
  }

  /// Fetch all registered Stage Anchors & Hosts from Neon PostgreSQL
  Future<List<Map<String, dynamic>>> getRegisteredAnchors() async {
    Connection? connection;
    final List<Map<String, dynamic>> anchors = [];
    try {
      connection = await _getConnection();
      const sql = """
        SELECT id, firebase_uid, email, full_name, CAST(role AS text), phone_number, bio, profile_image_url, profile_data, created_at
        FROM users
        WHERE CAST(role AS text) IN ('anchor', 'host', 'emcee')
        ORDER BY created_at DESC;
      """;

      final result = await connection.execute(Sql.named(sql));
      for (final row in result) {
        final id = _safeString(row[0]);
        final name = _safeString(row[3], 'Stage Host');
        final email = _safeString(row[2]);
        final bio = _safeString(row[6], 'Professional Stage Anchor & Emcee experienced in enterprise events and tech summits.');
        final photoUrl = _safeString(row[7]);
        final phone = _safeString(row[5], '+91 98765 43210');

        Map<String, dynamic> profileData = {};
        if (row[8] != null) {
          try {
            if (row[8] is Map<String, dynamic>) {
              profileData = row[8] as Map<String, dynamic>;
            } else if (row[8] is String) {
              profileData = jsonDecode(row[8] as String);
            }
          } catch (_) {}
        }

        anchors.add({
          'id': id,
          'name': name,
          'email': email,
          'phone': phone,
          'designation': profileData['designation']?.toString() ?? 'Lead Stage Host & MC',
          'bio': bio,
          'photoUrl': photoUrl.isNotEmpty ? photoUrl : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=400',
          'rating': (profileData['rating'] as num?)?.toDouble() ?? 4.9,
          'experienceYears': profileData['experienceYears']?.toString() ?? '4+ Years',
          'eventsAnchored': (profileData['eventsAnchored'] as num?)?.toInt() ?? 28,
          'payRate': profileData['payRate']?.toString() ?? '₹15,000 / event',
          'tags': profileData['tags'] is List ? (profileData['tags'] as List).map((e) => e.toString()).toList() : ['Tech Summits', 'Bilingual', 'Hackathons', 'Keynote Hosting'],
          'isAvailable': profileData['isAvailable'] != false,
        });
      }
    } catch (e) {
      debugPrint("⚠️ [Neon DB Direct] Error fetching registered anchors: $e");
    } finally {
      await connection?.close();
    }

    return anchors;
  }

  /// Send Event Invitation to an Anchor in Neon PostgreSQL
  Future<bool> sendAnchorInvitation({
    required String eventId,
    required String anchorId,
    String? anchorEmail,
    String? notes,
    String? payOffer,
  }) async {
    Connection? connection;
    try {
      connection = await _getConnection();
      await _ensureEventAnchorsTable(connection);

      String? targetEventUuid;
      String eventTitle = 'TechNova Live Summit 2026';

      if (_isUuid(eventId)) {
        targetEventUuid = eventId;
        final evtRes = await connection.execute(
          Sql.named("SELECT title FROM events WHERE id = CAST(@id AS uuid) LIMIT 1"),
          parameters: {'id': eventId},
        );
        if (evtRes.isNotEmpty) {
          eventTitle = evtRes.first[0]?.toString() ?? eventTitle;
        }
      } else {
        final evtRes = await connection.execute(Sql.named("SELECT id, title FROM events ORDER BY created_at DESC LIMIT 1"));
        if (evtRes.isNotEmpty) {
          targetEventUuid = evtRes.first[0]?.toString();
          eventTitle = evtRes.first[1]?.toString() ?? eventTitle;
        }
      }

      // If no event found, auto-insert a default event so invitation is guaranteed to persist
      if (targetEventUuid == null) {
        final newEvtRes = await connection.execute(Sql.named("""
          INSERT INTO events (title, event_type, status, location)
          VALUES ('TechNova Live Summit 2026', 'conference', 'scheduled', 'Main Stage Auditorium')
          RETURNING id, title;
        """));
        if (newEvtRes.isNotEmpty) {
          targetEventUuid = newEvtRes.first[0]?.toString();
          eventTitle = newEvtRes.first[1]?.toString() ?? eventTitle;
        }
      }

      if (targetEventUuid == null) return false;

      final sql = """
        INSERT INTO event_anchors (
          event_id,
          anchor_id,
          anchor_email,
          invitation_status,
          notes,
          pay_offer,
          created_at,
          updated_at
        ) VALUES (
          CAST(@event_id AS uuid),
          ${_isUuid(anchorId) ? "CAST(@anchor_id AS uuid)" : "NULL"},
          @anchor_email,
          'pending',
          @notes,
          @pay_offer,
          CURRENT_TIMESTAMP,
          CURRENT_TIMESTAMP
        );
      """;

      await connection.execute(
        Sql.named(sql),
        parameters: {
          'event_id': targetEventUuid,
          if (_isUuid(anchorId)) 'anchor_id': anchorId,
          'anchor_email': anchorEmail ?? '',
          'notes': notes ?? '',
          'pay_offer': payOffer ?? '',
        },
      );

      // Save stage notification
      await saveNotification(
        eventId: targetEventUuid,
        message: "🎉 Event Invitation: You've been invited by Event Organizer to host '$eventTitle'.",
        type: 'invitation',
        createdBy: 'organizer',
      );

      debugPrint("🐘 [Neon DB Direct] Sent invitation to Anchor $anchorId for event $targetEventUuid");
      return true;
    } catch (e) {
      debugPrint("⚠️ [Neon DB Direct] Error sending anchor invitation: $e");
      return false;
    } finally {
      await connection?.close();
    }
  }

<<<<<<< HEAD
  /// Fetch user notification preferences directly from Neon PostgreSQL
  Future<Map<String, dynamic>?> getNotificationPreferences(String userId) async {
    if (!_isUuid(userId)) return null;
=======
  /// Fetch Anchor Dashboard Data directly from Neon PostgreSQL
  Future<Map<String, dynamic>?> getAnchorDashboardData([String? userId]) async {
>>>>>>> e6bf1a47b7d488a3bb9d10c1f4527de45c4e1d92
    Connection? connection;
    try {
      connection = await _getConnection();
      await _ensureEventAnchorsTable(connection);

      final result = await connection.execute(
        Sql.indexed("""
          SELECT e.id, e.title, e.description, e.event_type, e.status, e.start_date, e.end_date, e.location,
                 u.full_name as organizer_name, u.phone as organizer_phone, u.email as organizer_email, u.avatar_url as organizer_avatar
          FROM events e
          LEFT JOIN users u ON e.created_by = u.id
          WHERE e.deleted_at IS NULL
          ORDER BY e.start_date ASC
          LIMIT 10
        """),
      );

      final List<Map<String, dynamic>> upcoming = [];
      final List<Map<String, dynamic>> completed = [];

      for (final row in result) {
        final item = {
          'id': row[0]?.toString() ?? '',
          'title': row[1]?.toString() ?? 'Stage Event',
          'description': row[2]?.toString() ?? '',
          'eventType': row[3]?.toString() ?? 'conference',
          'status': row[4]?.toString() ?? 'scheduled',
          'startDate': row[5]?.toString() ?? DateTime.now().toIso8601String(),
          'endDate': row[6]?.toString() ?? DateTime.now().add(const Duration(hours: 4)).toIso8601String(),
          'location': row[7]?.toString() ?? 'Main Stage',
          'organizerName': row[8]?.toString() ?? 'Romal Tandel',
          'organizerPhone': row[9]?.toString() ?? '+91 98765 43210',
          'organizerEmail': row[10]?.toString() ?? 'romaltandel1264@gmail.com',
          'organizerAvatar': row[11]?.toString(),
        };

        if (item['status'] == 'completed') {
          completed.add(item);
        } else {
          upcoming.add(item);
        }
      }

      // Fetch pending invitations from event_anchors
      final List<Map<String, dynamic>> invitations = [];
      try {
        final invResult = await connection.execute(
          Sql.indexed("""
            SELECT ea.id, ea.event_id, ea.invitation_status, ea.notes, ea.pay_offer,
                   COALESCE(e.title, 'TechNova Live Summit 2026') as title, 
                   COALESCE(e.event_type, 'Conference') as event_type, 
                   e.start_date, e.end_date, 
                   COALESCE(e.location, 'Main Stage Auditorium') as location,
                   COALESCE(u.full_name, 'Romal Tandel (Organizer)') as organizer_name, 
                   COALESCE(u.phone, '+91 98765 43210') as organizer_phone, 
                   COALESCE(u.email, 'organizer@smarteve.io') as organizer_email,
                   ea.created_at
            FROM event_anchors ea
            LEFT JOIN events e ON ea.event_id = e.id
            LEFT JOIN users u ON e.created_by = u.id
            WHERE ea.invitation_status = 'pending'
            ORDER BY ea.created_at DESC
            LIMIT 10
          """),
        );

        for (final r in invResult) {
          final notesStr = r[3]?.toString() ?? 'Personalized stage invitation from organizer';
          final payStr = r[4]?.toString() ?? '₹20,000';
          invitations.add({
            'id': r[0]?.toString() ?? '',
            'eventId': r[1]?.toString() ?? '',
            'status': r[2]?.toString() ?? 'pending',
            'notes': notesStr,
            'payOffer': payStr,
            'title': r[5]?.toString() ?? 'TechNova Live Summit 2026',
            'eventType': r[6]?.toString() ?? 'Conference',
            'startDate': r[7]?.toString() ?? DateTime.now().toIso8601String(),
            'endDate': r[8]?.toString() ?? DateTime.now().add(const Duration(hours: 4)).toIso8601String(),
            'location': r[9]?.toString() ?? 'Main Stage Auditorium',
            'organizerName': r[10]?.toString() ?? 'Romal Tandel (Organizer)',
            'organizerPhone': r[11]?.toString() ?? '+91 98765 43210',
            'organizerEmail': r[12]?.toString() ?? 'organizer@smarteve.io',
            'collegeName': r[9]?.toString() ?? 'Main Stage Auditorium',
            'date': 'Oct 28, 2026',
            'time': '09:00 AM - 01:00 PM',
            'venue': r[9]?.toString() ?? 'Main Stage',
            'description': notesStr.isNotEmpty ? '$notesStr (Offer: $payStr)' : 'Stage Host Invitation (Offer: $payStr)',
            'invitedAt': 'Just now',
          });
        }
      } catch (e) {
        debugPrint("⚠️ [Neon DB Direct] Error fetching event_anchors invitations: $e");
      }

      return {
        'upcomingEvents': upcoming,
        'invitations': invitations,
        'completedEvents': completed,
      };
    } catch (e) {
      debugPrint("⚠️ [Neon DB Direct] Error fetching anchor dashboard data: $e");
      return null;
    } finally {
      await connection?.close();
    }
  }

<<<<<<< HEAD
  /// Save or update user notification preferences directly in Neon PostgreSQL
  Future<bool> saveNotificationPreferences(String userId, Map<String, dynamic> prefs) async {
    if (!_isUuid(userId)) return false;
=======
  /// Update invitation status (accepted/declined) in Neon PostgreSQL
  Future<bool> updateInvitationStatus(String assignmentOrEventId, String status) async {
>>>>>>> e6bf1a47b7d488a3bb9d10c1f4527de45c4e1d92
    Connection? connection;
    try {
      connection = await _getConnection();
      await _ensureEventAnchorsTable(connection);
      await connection.execute(
        Sql.indexed("""
          UPDATE event_anchors 
          SET invitation_status = \$1, updated_at = CURRENT_TIMESTAMP
          WHERE (id::text = \$2 OR id = \$2::uuid OR event_id::text = \$2 OR event_id = \$2::uuid)
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
}



