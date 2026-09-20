import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:postgres/postgres.dart';
import '../../../core/network/api_client.dart';
import '../models/live_dashboard_models.dart';

class LiveDashboardProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final String eventId;
  bool _isDisposed = false;
  bool _isLoading = true;

  // Timers & Clock
  Timer? _tickerTimer;
  DateTime _now = DateTime.now();
  int _eventElapsedSeconds = 42 * 60 + 15; // 42m 15s into event
  final int _totalEventSeconds = 3 * 3600 + 30 * 60; // 3h 30m total
  int _activityElapsedSeconds = 8 * 60 + 20; // 8m 20s
  int _activityDurationSeconds = 15 * 60; // 15m duration
  int _scheduleDriftMinutes = 0; // 0 = on track

  // Auto-advance State
  Timer? _autoAdvanceTimer;
  bool _isAutoAdvancing = false;
  int _autoAdvanceCountdown = 3;

  // Real Event Data
  String _eventName = "SmartEve Live Tech Conclave 2026";
  String _eventVenue = "Main Stage & Grand Concourse";
  LiveActivityItem? _currentActivity;
  LiveActivityItem? _nextActivity;
  List<LiveActivityItem> _upcomingQueue = [];
  LiveScriptSnippet? _currentScript;
  LiveScriptSnippet? _nextScript;
  LiveAudienceMetrics _metrics = const LiveAudienceMetrics();
  LiveOrganizerContact _organizer = const LiveOrganizerContact(
    name: "Romal Tandel",
    phone: "+91 98765 43210",
    email: "romaltandel1264@gmail.com",
  );

  final List<LiveModeratorInfo> _moderators = [
    const LiveModeratorInfo(name: "Romal Tandel", role: "Chief Organizer", isOnline: true),
    const LiveModeratorInfo(name: "Chirag", role: "Co-Anchor", isOnline: true),
    const LiveModeratorInfo(name: "Stage Ops", role: "Backstage Manager", isOnline: true),
  ];

  final List<StageMessage> _stageMessages = [
    StageMessage(
      id: "msg-1",
      senderName: "Stage Manager",
      senderRole: "Backstage Ops",
      message: "Mic check 2 verified for speaker Bhautik Jogiya.",
      timestamp: DateTime.now().subtract(const Duration(minutes: 6)),
    ),
    StageMessage(
      id: "msg-2",
      senderName: "Romal Tandel",
      senderRole: "Organizer",
      message: "Audience QA will have handheld mic runners in aisles A & B.",
      timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
  ];

  String _anchorNotes = "Remember to announce the networking lounge sponsors before the break.";

  // Getters
  bool get isLoading => _isLoading;
  DateTime get now => _now;
  String get currentTimeFormatted => DateFormat('HH:mm:ss').format(_now);
  int get eventElapsedSeconds => _eventElapsedSeconds;
  int get totalEventSeconds => _totalEventSeconds;
  int get activityElapsedSeconds => _activityElapsedSeconds;
  int get activityDurationSeconds => _activityDurationSeconds;
  int get activityRemainingSeconds => _activityDurationSeconds - _activityElapsedSeconds;
  bool get isOverdue => activityRemainingSeconds < 0;

  int get scheduleDriftMinutes => _scheduleDriftMinutes;
  ScheduleDriftStatus get scheduleStatus {
    // Spec: Green = On Schedule, Yellow = Running behind (< 5 mins),
    // Red = Significantly delayed (> 5 mins).
    if (_scheduleDriftMinutes > 5 || isOverdue && -activityRemainingSeconds > 5 * 60) {
      return ScheduleDriftStatus.significantlyDelayed;
    }
    if (_scheduleDriftMinutes > 0 || isOverdue) {
      return ScheduleDriftStatus.runningBehind;
    }
    return ScheduleDriftStatus.onSchedule;
  }

  /// Human-readable drift chip, e.g. "On Schedule" / "Running Behind (+3m)".
  String get scheduleStatusLabel {
    if (_scheduleDriftMinutes == 0 && !isOverdue) return scheduleStatus.label;
    final sign = _scheduleDriftMinutes > 0 ? '+' : '';
    return "${scheduleStatus.label} ($sign${_scheduleDriftMinutes}m)";
  }

  bool get isAutoAdvancing => _isAutoAdvancing;
  int get autoAdvanceCountdown => _autoAdvanceCountdown;

  String get eventName => _eventName;
  String get eventVenue => _eventVenue;
  LiveActivityItem? get currentActivity => _currentActivity;
  LiveActivityItem? get nextActivity => _nextActivity;
  List<LiveActivityItem> get upcomingQueue => _upcomingQueue;
  LiveScriptSnippet? get currentScript => _currentScript;
  LiveScriptSnippet? get nextScript => _nextScript;
  LiveAudienceMetrics get metrics => _metrics;
  LiveOrganizerContact get organizer => _organizer;
  List<LiveModeratorInfo> get moderators => _moderators;
  int get onlineModeratorsCount => _moderators.where((m) => m.isOnline).length;
  List<StageMessage> get stageMessages => _stageMessages;
  String get anchorNotes => _anchorNotes;

  // --- Immersive dashboard additions (spec compliance) ---

  /// Completed activities fade out into history instead of disappearing.
  final List<LiveActivityItem> _completedHistory = [];
  List<LiveActivityItem> get completedHistory =>
      List.unmodifiable(_completedHistory);

  /// Notification bell badge: unread organizer / backstage messages.
  int _unreadMessagesCount = 2;
  int get unreadMessagesCount => _unreadMessagesCount;

  /// Optional notification sound for "Next activity in 1 min".
  bool _soundEnabled = true;
  bool get soundEnabled => _soundEnabled;

  /// Anchor presence broadcast to organizer: ready / delayed / sos.
  String _anchorStatus = "ready";
  String get anchorStatus => _anchorStatus;

  /// Time until the next activity starts (driven by current remaining time).
  int get timeUntilNextSeconds =>
      activityRemainingSeconds > 0 ? activityRemainingSeconds : 0;

  /// True when the next activity begins within 60 seconds.
  bool get isNextImminent =>
      _nextActivity != null &&
      activityRemainingSeconds <= 60 &&
      activityRemainingSeconds > 0;

  void toggleSound() {
    _soundEnabled = !_soundEnabled;
    _safeNotifyListeners();
  }

  void setAnchorStatus(String status) {
    _anchorStatus = status;
    _safeNotifyListeners();
  }

  void markMessagesRead() {
    _unreadMessagesCount = 0;
    _safeNotifyListeners();
  }

  /// Called by Firebase/FCM listeners when the organizer pushes an update.
  /// Returns a user-facing toast string so the UI can show sound + banner.
  String? onOrganizerDelayNotification({
    required int delayMinutes,
    String? reason,
  }) {
    _activityDurationSeconds += delayMinutes * 60;
    _scheduleDriftMinutes += delayMinutes;
    _stageMessages.insert(
      0,
      StageMessage(
        id: "msg-${DateTime.now().millisecondsSinceEpoch}",
        senderName: "Organizer",
        senderRole: "Control Room",
        message:
            "⏱ Schedule shift: +$delayMinutes min${reason != null && reason.isNotEmpty ? " — $reason" : ""}. Timings auto-reflowed.",
        timestamp: DateTime.now(),
        isUrgent: true,
      ),
    );
    _unreadMessagesCount++;
    _safeNotifyListeners();
    return "Organizer delayed stage by +$delayMinutes min";
  }

  /// Called when the organizer forces "Move to next activity".
  String onOrganizerMoveNext() {
    advanceToNextActivity();
    return "Organizer moved stage to next activity";
  }

  /// Called when a new organizer/backstage message arrives via FCM.
  void onRemoteStageMessage({
    required String senderName,
    required String senderRole,
    required String message,
    bool isUrgent = false,
  }) {
    _stageMessages.insert(
      0,
      StageMessage(
        id: "msg-${DateTime.now().millisecondsSinceEpoch}",
        senderName: senderName,
        senderRole: senderRole,
        message: message,
        timestamp: DateTime.now(),
        isUrgent: isUrgent,
      ),
    );
    _unreadMessagesCount++;
    _safeNotifyListeners();
  }

  LiveDashboardProvider({required this.eventId}) {
    _startTicker();
    loadLiveState();
  }

  void _safeNotifyListeners() {
    if (_isDisposed) return;
    notifyListeners();
  }

  void _startTicker() {
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _now = DateTime.now();
      _eventElapsedSeconds++;
      _activityElapsedSeconds++;
      _safeNotifyListeners();
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _tickerTimer?.cancel();
    _autoAdvanceTimer?.cancel();
    super.dispose();
  }

  String formatDuration(int totalSeconds) {
    final abs = totalSeconds.abs();
    final h = abs ~/ 3600;
    final m = (abs % 3600) ~/ 60;
    final s = abs % 60;
    if (h > 0) {
      return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
    }
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  /// Load Live Stage State from Backend API or Neon Direct
  Future<void> loadLiveState() async {
    _isLoading = true;
    _safeNotifyListeners();

    try {
      final res = await _apiClient.get('/anchor/events/$eventId/live');
      if (res.success && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        _applyLivePayload(data);
      } else {
        await _fetchDirectFromNeon();
      }
    } catch (_) {
      await _fetchDirectFromNeon();
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  void _applyLivePayload(Map<String, dynamic> data) {
    if (data['event'] is Map) {
      final ev = data['event'] as Map;
      _eventName = ev['title']?.toString() ?? _eventName;
      _eventVenue = ev['location']?.toString() ?? _eventVenue;
      if (ev['organizer'] is Map) {
        _organizer = LiveOrganizerContact.fromJson(ev['organizer'] as Map<String, dynamic>);
      }
    }

    if (data['currentActivity'] is Map) {
      _currentActivity = LiveActivityItem.fromJson(data['currentActivity'] as Map<String, dynamic>);
      _activityDurationSeconds = (_currentActivity!.durationMinutes) * 60;
    }

    if (data['nextActivity'] is Map) {
      _nextActivity = LiveActivityItem.fromJson(data['nextActivity'] as Map<String, dynamic>);
    }

    if (data['upcomingQueue'] is List) {
      _upcomingQueue = (data['upcomingQueue'] as List)
          .map((item) => LiveActivityItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    if (data['currentScript'] is Map) {
      _currentScript = LiveScriptSnippet.fromJson(data['currentScript'] as Map<String, dynamic>);
    }

    if (data['nextScript'] is Map) {
      _nextScript = LiveScriptSnippet.fromJson(data['nextScript'] as Map<String, dynamic>);
    }

    if (data['metrics'] is Map) {
      _metrics = LiveAudienceMetrics.fromJson(data['metrics'] as Map<String, dynamic>);
    }
  }

  /// Direct Neon PostgreSQL query fallback
  Future<void> _fetchDirectFromNeon() async {
    Connection? conn;
    try {
      final endpoint = Endpoint(
        host: 'ep-lingering-river-b48n0foj.c-6.us-east-2.aws.neon.tech',
        database: 'neondb',
        username: 'neondb_owner',
        password: 'npg_OAEhqtznw7D8',
        port: 5432,
      );
      conn = await Connection.open(
        endpoint,
        settings: const ConnectionSettings(sslMode: SslMode.require),
      );

      // 1. Fetch Event & Organizer
      final evRows = await conn.execute(Sql.indexed("""
        SELECT e.title, e.location, u.full_name, u.phone_number, u.email
        FROM events e
        LEFT JOIN users u ON e.created_by = u.id
        WHERE e.id = \$1::uuid
      """), parameters: [eventId]);

      if (evRows.isNotEmpty) {
        final row = evRows.first;
        _eventName = row[0]?.toString() ?? _eventName;
        _eventVenue = row[1]?.toString() ?? _eventVenue;
        _organizer = LiveOrganizerContact(
          name: row[2]?.toString() ?? "Romal Tandel",
          phone: row[3]?.toString() ?? "+91 98765 43210",
          email: row[4]?.toString() ?? "romaltandel1264@gmail.com",
        );
      }

      // 2. Fetch Agenda Items & Speakers
      final agendaRows = await conn.execute(Sql.indexed("""
        SELECT 
          a.id, a.title, a.type, a.description, a.duration_minutes, a.status,
          s.id, s.name, s.topic, s.designation, s.organization, s.photo_url
        FROM agenda_items a
        LEFT JOIN speakers s ON a.speaker_id = s.id
        WHERE a.event_id = \$1::uuid
        ORDER BY a.order_in_agenda ASC
      """), parameters: [eventId]);

      final List<LiveActivityItem> items = [];
      for (final r in agendaRows) {
        LiveSpeakerInfo? spk;
        if (r[7] != null) {
          spk = LiveSpeakerInfo(
            id: r[6]?.toString() ?? '',
            name: r[7]?.toString() ?? '',
            topic: r[8]?.toString(),
            designation: r[9]?.toString(),
            organization: r[10]?.toString(),
            photoUrl: r[11]?.toString(),
          );
        }

        items.add(LiveActivityItem(
          id: r[0]?.toString() ?? '',
          title: r[1]?.toString() ?? 'Stage Session',
          type: r[2]?.toString() ?? 'keynote',
          description: r[3]?.toString(),
          durationMinutes: int.tryParse(r[4]?.toString() ?? '') ?? 15,
          status: r[5]?.toString() ?? 'scheduled',
          speaker: spk,
        ));
      }

      if (items.isNotEmpty) {
        _currentActivity = items.first;
        _activityDurationSeconds = _currentActivity!.durationMinutes * 60;
        _activityElapsedSeconds = 120; // 2m in
        if (items.length > 1) {
          _nextActivity = items[1];
          _upcomingQueue = items.sublist(2);
        }
      }

      // 3. Fetch Scripts
      final scriptRows = await conn.execute(Sql.indexed("""
        SELECT id, script_type, title, content, is_approved, tone
        FROM ai_scripts
        WHERE event_id = \$1::uuid
        ORDER BY created_at ASC
      """), parameters: [eventId]);

      if (scriptRows.isNotEmpty) {
        final first = scriptRows.first;
        _currentScript = LiveScriptSnippet(
          id: first[0]?.toString() ?? '',
          type: first[1]?.toString() ?? 'opening',
          title: first[2]?.toString() ?? 'Opening Remarks',
          content: first[3]?.toString() ?? '',
          isApproved: first[4] == true,
          tone: first[5]?.toString() ?? 'Motivational',
        );

        if (scriptRows.length > 1) {
          final snd = scriptRows[1];
          _nextScript = LiveScriptSnippet(
            id: snd[0]?.toString() ?? '',
            type: snd[1]?.toString() ?? 'speaker_intro',
            title: snd[2]?.toString() ?? 'Speaker Introduction',
            content: snd[3]?.toString() ?? '',
            isApproved: snd[4] == true,
            tone: snd[5]?.toString() ?? 'Inspiring',
          );
        }
      }
    } catch (e) {
      debugPrint("⚠️ [Live Dashboard Direct Neon Fetch] Error: $e");
    } finally {
      await conn?.close();
    }
  }

  // --- Live Stage Actions ---

  /// Starts the 3-second auto-advance confirmation countdown
  void startAutoAdvanceCountdown() {
    if (_isAutoAdvancing) return;
    _isAutoAdvancing = true;
    _autoAdvanceCountdown = 3;
    _safeNotifyListeners();

    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_autoAdvanceCountdown > 1) {
        _autoAdvanceCountdown--;
        _safeNotifyListeners();
      } else {
        _autoAdvanceTimer?.cancel();
        _isAutoAdvancing = false;
        advanceToNextActivity();
      }
    });
  }

  /// Cancel the active countdown
  void cancelAutoAdvance() {
    _autoAdvanceTimer?.cancel();
    _isAutoAdvancing = false;
    _safeNotifyListeners();
  }

  /// Immediately complete current activity and roll forward
  Future<void> advanceToNextActivity() async {
    cancelAutoAdvance();

    final completedItem = _currentActivity;
    if (completedItem != null) {
      // Completed activities fade out into history (immersive visual cue).
      _completedHistory.insert(0, completedItem.copyWith(status: "completed"));
      if (_completedHistory.length > 10) {
        _completedHistory.removeLast();
      }
    }
    if (_nextActivity != null) {
      _currentActivity = _nextActivity;
      _activityElapsedSeconds = 0;
      _activityDurationSeconds = _currentActivity!.durationMinutes * 60;

      if (_upcomingQueue.isNotEmpty) {
        _nextActivity = _upcomingQueue.removeAt(0);
      } else {
        _nextActivity = null;
      }

      // Rotate scripts
      if (_nextScript != null) {
        _currentScript = _nextScript;
        _nextScript = null;
      }
    }

    _safeNotifyListeners();

    // Sync with backend / Neon
    if (completedItem != null) {
      try {
        await _apiClient.post(
          '/anchor/events/$eventId/agenda/${completedItem.id}/progress',
          {'action': 'complete'},
        );
      } catch (_) {}
    }
  }

  /// Delay the current activity and recalculate schedule
  Future<void> delayActivity({
    required int minutes,
    required bool notifyAll,
    String? reason,
    String? activityId,
  }) async {
    _activityDurationSeconds += minutes * 60;
    _scheduleDriftMinutes += minutes;
    // Broadcast anchor presence so organizer sees delayed status.
    _anchorStatus = "delayed";

    if (notifyAll) {
      final reasonSuffix =
          reason != null && reason.trim().isNotEmpty ? " — ${reason.trim()}" : "";
      _stageMessages.insert(
        0,
        StageMessage(
          id: "msg-${DateTime.now().millisecondsSinceEpoch}",
          senderName: "Stage Anchor",
          senderRole: "Live Stage",
          message:
              "⚠️ Schedule updated: Stage delayed by +$minutes minutes$reasonSuffix.",
          timestamp: DateTime.now(),
          isUrgent: true,
        ),
      );
    }

    _safeNotifyListeners();

    try {
      await _apiClient.post(
        '/anchor/events/$eventId/delay',
        {
          'delayMinutes': minutes,
          'itemId': activityId ?? _currentActivity?.id,
          'notifyAll': notifyAll,
          if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
        },
      );
    } catch (_) {}
  }

  /// Send stage announcement with optional AI polished wording
  Future<void> sendAnnouncement({
    required String message,
    required String type,
    required String priority,
    bool sendToOrganizerForApproval = false,
  }) async {
    _stageMessages.insert(
      0,
      StageMessage(
        id: "msg-${DateTime.now().millisecondsSinceEpoch}",
        senderName: sendToOrganizerForApproval ? "Stage Anchor (pending approval)" : "Stage Anchor",
        senderRole: "Public Announcement",
        message: message,
        timestamp: DateTime.now(),
        isUrgent: priority == "urgent",
      ),
    );
    _safeNotifyListeners();

    try {
      await _apiClient.post(
        '/anchor/events/$eventId/announcement',
        {
          'message': message,
          'type': type,
          'priority': priority,
          'sendToOrganizerForApproval': sendToOrganizerForApproval,
        },
      );
    } catch (_) {}
  }

  /// Insert an unplanned activity live on stage
  Future<void> addUnplannedActivity({
    required String title,
    required int durationMinutes,
    required String description,
    bool insertNext = true,
  }) async {
    final newItem = LiveActivityItem(
      id: "unplanned-${DateTime.now().millisecondsSinceEpoch}",
      title: title,
      type: "activity",
      description: description,
      durationMinutes: durationMinutes,
      status: "scheduled",
    );

    if (insertNext) {
      if (_nextActivity != null) {
        _upcomingQueue.insert(0, _nextActivity!);
      }
      _nextActivity = newItem;
    } else {
      _upcomingQueue.add(newItem);
    }

    _safeNotifyListeners();

    try {
      await _apiClient.post(
        '/anchor/events/$eventId/unplanned-activity',
        {
          'title': title,
          'durationMinutes': durationMinutes,
          'description': description,
          'type': 'activity',
        },
      );
    } catch (_) {}
  }

  /// Reorder upcoming queue
  void reorderUpcomingQueue(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = _upcomingQueue.removeAt(oldIndex);
    _upcomingQueue.insert(newIndex, item);
    _safeNotifyListeners();
  }

  /// Register live audience reaction
  Future<void> sendReaction(String reactionKey) async {
    _metrics = _metrics.copyWithReaction(reactionKey);
    _safeNotifyListeners();

    try {
      await _apiClient.post(
        '/anchor/events/$eventId/reactions',
        {'reaction': reactionKey},
      );
    } catch (_) {}
  }

  /// Post stage chat message to backstage team
  void postStageMessage(String text, {bool isUrgent = false}) {
    if (text.trim().isEmpty) return;
    _stageMessages.insert(
      0,
      StageMessage(
        id: "msg-${DateTime.now().millisecondsSinceEpoch}",
        senderName: "Stage Anchor",
        senderRole: "On-Stage",
        message: text.trim(),
        timestamp: DateTime.now(),
        isUrgent: isUrgent,
      ),
    );
    _safeNotifyListeners();
  }

  /// Update anchor notes
  void updateAnchorNotes(String notes) {
    _anchorNotes = notes;
    _safeNotifyListeners();
  }
}
