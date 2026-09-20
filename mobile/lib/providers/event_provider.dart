import 'dart:async';
import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/services/neon_database_service.dart';
import '../models/agenda_item_model.dart';
import '../models/event_model.dart';
import '../models/notification_model.dart';
import '../models/script_model.dart';
import '../models/speaker_model.dart';

class EventProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final NeonDatabaseService _neonService = NeonDatabaseService();

  EventModel? _event;
  List<EventModel> _organizerEvents = [];
  List<AgendaItemModel> _agenda = [];
  List<SpeakerModel> _speakers = [];
  final List<NotificationModel> _notifications = [];
  ScriptModel? _activeScript;

  bool _isLoading = false;
  bool _isDisposed = false;
  String? _errorMessage;
  Timer? _tickerTimer;
  Timer? _liveSyncTimer;
  List<Map<String, dynamic>> _qnaQuestions = [];

  EventModel? get event => _event;
  List<EventModel> get organizerEvents => _organizerEvents;
  List<AgendaItemModel> get agenda => _agenda;
  List<SpeakerModel> get speakers => _speakers;
  List<NotificationModel> get notifications => _notifications;
  List<Map<String, dynamic>> get qnaQuestions => _qnaQuestions;
  ScriptModel? get activeScript => _activeScript;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  EventProvider() {
    _startTicker();
    _startLiveSync();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _tickerTimer?.cancel();
    _liveSyncTimer?.cancel();
    super.dispose();
  }

  /// Guards async completions that land after dispose.
  void _safeNotifyListeners() {
    if (_isDisposed) return;
    notifyListeners();
  }

  void _startTicker() {
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_event?.liveState.status == 'live') {
        notifyListeners();
      }
    });
  }

  void _startLiveSync() {
    _liveSyncTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (_event != null) {
        await _performSilentLiveSync();
      }
    });
  }

  Future<void> _performSilentLiveSync() async {
    try {
      final updatedAgenda = await NeonDatabaseService().getAgendaForEvent(_event?.id);
      if (updatedAgenda.isNotEmpty) {
        _agenda = updatedAgenda.map((map) => AgendaItemModel.fromJson(map)).toList();
      }
      final updatedQna = await NeonDatabaseService().getQnaQuestions(_event?.id);
      _qnaQuestions = updatedQna;
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> submitQnaQuestion(String question, {String? authorName}) async {
    final name = authorName?.trim().isNotEmpty == true ? authorName!.trim() : 'Attendee';
    final targetEventId = _event?.id ?? 'default_event';
    final currentSessionId = currentSession?.id;

    final success = await NeonDatabaseService().saveQnaQuestion(
      eventId: targetEventId,
      authorName: name,
      question: question,
      sessionId: currentSessionId,
    );

    if (success) {
      await fetchQnaQuestions();
      return true;
    }
    return false;
  }

  Future<void> fetchQnaQuestions() async {
    try {
      final res = await NeonDatabaseService().getQnaQuestions(_event?.id);
      _qnaQuestions = res;
      notifyListeners();
    } catch (_) {}
  }

  AgendaItemModel? get currentSession {
    if (_event == null || _agenda.isEmpty) return null;
    final currentId = _event!.liveState.currentItemId;
    if (currentId != null) {
      final found = _agenda.where((it) => it.id == currentId);
      if (found.isNotEmpty) return found.first;
    }
    final liveItem = _agenda.where((it) => it.isLive);
    if (liveItem.isNotEmpty) return liveItem.first;
    return null;
  }

  AgendaItemModel? get nextSession {
    final current = currentSession;
    if (current == null) {
      final upcoming = _agenda.where((it) => it.isUpcoming).toList();
      return upcoming.isNotEmpty ? upcoming.first : null;
    }
    final later = _agenda
        .where((it) => it.order > current.order && it.isUpcoming)
        .toList();
    return later.isNotEmpty ? later.first : null;
  }

  SpeakerModel? get currentSpeaker {
    final session = currentSession;
    if (session == null || session.speakerIds.isEmpty) return null;
    final found = _speakers.where((s) => s.id == session.speakerIds.first);
    return found.isNotEmpty ? found.first : null;
  }

  int get remainingSeconds {
    final session = currentSession;
    if (session == null || session.endTime.isEmpty) return 0;
    final end = DateTime.tryParse(session.endTime);
    if (end == null) return 0;
    final now = DateTime.now();
    return end.difference(now).inSeconds;
  }

  String get formattedCountdown {
    final sec = remainingSeconds;
    final isOvertime = sec < 0;
    final abs = sec.abs();
    final minutes = (abs ~/ 60).toString().padLeft(2, '0');
    final seconds = (abs % 60).toString().padLeft(2, '0');
    return '${isOvertime ? "+" : ""}$minutes:$seconds';
  }

  double get progressFraction {
    final session = currentSession;
    if (session == null) return 0.0;
    final start = DateTime.tryParse(session.startTime);
    final end = DateTime.tryParse(session.endTime);
    if (start == null || end == null) return 0.0;
    final total = end.difference(start).inSeconds;
    if (total <= 0) return 0.0;
    final elapsed = DateTime.now().difference(start).inSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  Future<void> loadEvent(String eventId) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotifyListeners();

    try {
      final eventRes = await _apiClient.get('/events/$eventId');
      if (eventRes.success && eventRes.data != null) {
        _event = EventModel.fromJson(eventRes.data as Map<String, dynamic>);
        await fetchAgenda(eventId);
        await fetchSpeakers(eventId);
      } else {
        await _fetchFromNeon(eventId);
      }

      if (_event == null) {
        debugPrint("ℹ️ [EventProvider] Event $eventId not loaded, trying direct Neon DB.");
        await _fetchFromNeon(eventId);
      }
    } catch (e) {
      _errorMessage = e.toString();
      await _fetchFromNeon(eventId);
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  Future<void> _fetchFromNeon(String eventId) async {
    try {
      final evData = await _neonService.getEventDetails(eventId).timeout(const Duration(seconds: 1));
      if (evData != null) {
        _event = EventModel(
          id: evData['id'] ?? eventId,
          name: evData['title'] ?? 'TechNova Live AI Summit 2026',
          type: evData['eventType'] ?? 'Conference',
          date: evData['startDate'] != null ? evData['startDate'].toString().split('T')[0] : '2026-09-20',
          venue: evData['location'] ?? 'Main Auditorium & Stage A',
          tone: 'Visionary & Polished',
          ownerId: evData['organizerName'] ?? 'Romal Tandel',
          joinCode: 'TN26',
          liveState: LiveStateModel(
            status: evData['status'] ?? 'live',
            currentItemId: null,
            startedAt: DateTime.now().millisecondsSinceEpoch - 15 * 60 * 1000,
            totalDelayMin: 0,
          ),
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );
      }

      final agendaData = await _neonService.getAgendaItems(eventId);
      if (agendaData.isNotEmpty) {
        _agenda = agendaData.map((m) => AgendaItemModel.fromJson(m)).toList();
      }

      final spkData = await _neonService.getSpeakers(eventId);
      if (spkData.isNotEmpty) {
        _speakers = spkData.map((m) => SpeakerModel.fromJson(m)).toList();
      }
    } catch (_) {}
  }

  Future<bool> startEvent() async {
    if (_event == null) return false;
    _isLoading = true;
    _safeNotifyListeners();

    try {
      final now = DateTime.now();
      String? firstLiveId;
      if (_agenda.isNotEmpty) {
        firstLiveId = _agenda[0].id;
        final updatedAgenda = <AgendaItemModel>[];
        for (int i = 0; i < _agenda.length; i++) {
          final item = _agenda[i];
          if (i == 0) {
            final startDt = now;
            final endDt = startDt.add(Duration(minutes: item.duration));
            updatedAgenda.add(AgendaItemModel(
              id: item.id,
              order: item.order,
              title: item.title,
              type: item.type,
              speakerIds: item.speakerIds,
              duration: item.duration,
              plannedStart: item.plannedStart.isNotEmpty ? item.plannedStart : startDt.toIso8601String(),
              startTime: startDt.toIso8601String(),
              endTime: endDt.toIso8601String(),
              status: 'live',
              absorbable: item.absorbable,
              minDuration: item.minDuration,
              hardStart: item.hardStart,
              notes: item.notes,
            ));
          } else {
            updatedAgenda.add(item);
          }
        }
        _agenda = updatedAgenda;
        await NeonDatabaseService().updateAgendaTimingsBatch(_agenda, targetEventId: _event!.id);
      }

      _event = EventModel(
        id: _event!.id,
        name: _event!.name,
        type: _event!.type,
        date: _event!.date,
        venue: _event!.venue,
        tone: _event!.tone,
        description: _event!.description,
        ownerId: _event!.ownerId,
        joinCode: _event!.joinCode,
        anchorIds: _event!.anchorIds,
        liveState: LiveStateModel(
          status: 'live',
          currentItemId: firstLiveId,
          startedAt: now.millisecondsSinceEpoch,
          totalDelayMin: 0,
        ),
        createdAt: _event!.createdAt,
      );

      await NeonDatabaseService().updateEventStatus(_event!.id, 'live');

      try {
        await _apiClient.post('/events/${_event!.id}/start', {});
      } catch (_) {}

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    _safeNotifyListeners();
    return false;
  }

  Future<bool> injectDelay(int minutes, {String? reason}) async {
    if (_event == null || _agenda.isEmpty) return false;
    _isLoading = true;
    _safeNotifyListeners();

    try {
      final now = DateTime.now();
      int currentIdx = _agenda.indexWhere((it) => it.isLive);
      if (currentIdx == -1) {
        currentIdx = _agenda.indexWhere((it) => it.isUpcoming);
        if (currentIdx == -1) currentIdx = 0;
      }

      final updatedAgenda = List<AgendaItemModel>.from(_agenda);
      int remainingShift = minutes;

      final currentItem = updatedAgenda[currentIdx];
      DateTime currentStart = DateTime.tryParse(currentItem.startTime) ?? now;
      int newDuration = currentItem.duration;
      if (minutes > 0) {
        newDuration += minutes;
      }
      DateTime currentEnd = currentStart.add(Duration(minutes: newDuration));

      updatedAgenda[currentIdx] = AgendaItemModel(
        id: currentItem.id,
        order: currentItem.order,
        title: currentItem.title,
        type: currentItem.type,
        speakerIds: currentItem.speakerIds,
        duration: newDuration,
        plannedStart: currentItem.plannedStart,
        startTime: currentStart.toIso8601String(),
        endTime: currentEnd.toIso8601String(),
        status: 'live',
        absorbable: currentItem.absorbable,
        minDuration: currentItem.minDuration,
        hardStart: currentItem.hardStart,
        notes: currentItem.notes,
      );

      DateTime prevEnd = currentEnd;
      for (int i = currentIdx + 1; i < updatedAgenda.length; i++) {
        var item = updatedAgenda[i];
        if (item.isDone || item.status == 'skipped') continue;

        int itemDur = item.duration;
        if (item.absorbable && remainingShift > 0) {
          int minDur = item.minDuration ?? 5;
          int availableBuffer = itemDur - minDur;
          if (availableBuffer > 0) {
            int absorbed = remainingShift <= availableBuffer ? remainingShift : availableBuffer;
            itemDur -= absorbed;
            remainingShift -= absorbed;
          }
        }

        DateTime nextStart = prevEnd;
        DateTime nextEnd = nextStart.add(Duration(minutes: itemDur));
        prevEnd = nextEnd;

        updatedAgenda[i] = AgendaItemModel(
          id: item.id,
          order: item.order,
          title: item.title,
          type: item.type,
          speakerIds: item.speakerIds,
          duration: itemDur,
          plannedStart: item.plannedStart,
          startTime: nextStart.toIso8601String(),
          endTime: nextEnd.toIso8601String(),
          status: item.status,
          absorbable: item.absorbable,
          minDuration: item.minDuration,
          hardStart: item.hardStart,
          notes: item.notes,
        );
      }

      _agenda = updatedAgenda;
      await NeonDatabaseService().updateAgendaTimingsBatch(_agenda, targetEventId: _event!.id);

      _notifications.insert(
        0,
        NotificationModel(
          id: 'notif-${now.millisecondsSinceEpoch}',
          type: 'delay',
          message: "⏰ Schedule Reflow (+${minutes}m): ${reason ?? 'Stage adjustment applied across upcoming agenda items.'}",
          createdBy: 'organizer',
          createdAt: now.millisecondsSinceEpoch,
        ),
      );

      try {
        await _apiClient.post('/events/${_event!.id}/delay', {
          'delayMinutes': minutes,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        });
      } catch (_) {}

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      try {
        await _neonService.delayAgendaItem(_event!.id, currentSession?.id, minutes, reason);
      } catch (_) {}
    }
    _isLoading = false;
    _safeNotifyListeners();
    return false;
  }

  Future<bool> completeCurrentSession() async {
    if (_event == null || _agenda.isEmpty) return false;
    _isLoading = true;
    _safeNotifyListeners();

    try {
      final now = DateTime.now();
      int currentIdx = _agenda.indexWhere((it) => it.isLive);
      if (currentIdx == -1) {
        currentIdx = _agenda.indexWhere((it) => it.isUpcoming);
        if (currentIdx == -1) currentIdx = 0;
      }

      final updatedAgenda = List<AgendaItemModel>.from(_agenda);
      final finishedItem = updatedAgenda[currentIdx];

      updatedAgenda[currentIdx] = AgendaItemModel(
        id: finishedItem.id,
        order: finishedItem.order,
        title: finishedItem.title,
        type: finishedItem.type,
        speakerIds: finishedItem.speakerIds,
        duration: finishedItem.duration,
        plannedStart: finishedItem.plannedStart,
        startTime: finishedItem.startTime,
        endTime: now.toIso8601String(),
        status: 'done',
        absorbable: finishedItem.absorbable,
        minDuration: finishedItem.minDuration,
        hardStart: finishedItem.hardStart,
        notes: finishedItem.notes,
      );

      String? nextLiveId;
      if (currentIdx + 1 < updatedAgenda.length) {
        final nextItem = updatedAgenda[currentIdx + 1];
        nextLiveId = nextItem.id;
        final nextStart = now;
        final nextEnd = nextStart.add(Duration(minutes: nextItem.duration));

        updatedAgenda[currentIdx + 1] = AgendaItemModel(
          id: nextItem.id,
          order: nextItem.order,
          title: nextItem.title,
          type: nextItem.type,
          speakerIds: nextItem.speakerIds,
          duration: nextItem.duration,
          plannedStart: nextItem.plannedStart,
          startTime: nextStart.toIso8601String(),
          endTime: nextEnd.toIso8601String(),
          status: 'live',
          absorbable: nextItem.absorbable,
          minDuration: nextItem.minDuration,
          hardStart: nextItem.hardStart,
          notes: nextItem.notes,
        );
      }

      _agenda = updatedAgenda;
      await NeonDatabaseService().updateAgendaTimingsBatch(_agenda, targetEventId: _event!.id);

      final isAllDone = currentIdx + 1 >= updatedAgenda.length;
      _event = EventModel(
        id: _event!.id,
        name: _event!.name,
        type: _event!.type,
        date: _event!.date,
        venue: _event!.venue,
        tone: _event!.tone,
        description: _event!.description,
        ownerId: _event!.ownerId,
        joinCode: _event!.joinCode,
        anchorIds: _event!.anchorIds,
        liveState: LiveStateModel(
          status: isAllDone ? 'completed' : 'live',
          currentItemId: nextLiveId,
          startedAt: _event!.liveState.startedAt,
          totalDelayMin: _event!.liveState.totalDelayMin,
        ),
        createdAt: _event!.createdAt,
      );

      if (isAllDone) {
        await NeonDatabaseService().updateEventStatus(_event!.id, 'completed');
      }

      try {
        await _apiClient.post('/events/${_event!.id}/complete-current', {});
      } catch (_) {}

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> skipCurrentSession() async {
    if (_event == null || _agenda.isEmpty) return false;
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      int currentIdx = _agenda.indexWhere((it) => it.isLive);
      if (currentIdx == -1) currentIdx = 0;

      final updatedAgenda = List<AgendaItemModel>.from(_agenda);
      final skippedItem = updatedAgenda[currentIdx];

      updatedAgenda[currentIdx] = AgendaItemModel(
        id: skippedItem.id,
        order: skippedItem.order,
        title: skippedItem.title,
        type: skippedItem.type,
        speakerIds: skippedItem.speakerIds,
        duration: skippedItem.duration,
        plannedStart: skippedItem.plannedStart,
        startTime: skippedItem.startTime,
        endTime: now.toIso8601String(),
        status: 'skipped',
        absorbable: skippedItem.absorbable,
        minDuration: skippedItem.minDuration,
        hardStart: skippedItem.hardStart,
        notes: skippedItem.notes,
      );

      String? nextLiveId;
      if (currentIdx + 1 < updatedAgenda.length) {
        final nextItem = updatedAgenda[currentIdx + 1];
        nextLiveId = nextItem.id;
        final nextStart = now;
        final nextEnd = nextStart.add(Duration(minutes: nextItem.duration));

        updatedAgenda[currentIdx + 1] = AgendaItemModel(
          id: nextItem.id,
          order: nextItem.order,
          title: nextItem.title,
          type: nextItem.type,
          speakerIds: nextItem.speakerIds,
          duration: nextItem.duration,
          plannedStart: nextItem.plannedStart,
          startTime: nextStart.toIso8601String(),
          endTime: nextEnd.toIso8601String(),
          status: 'live',
          absorbable: nextItem.absorbable,
          minDuration: nextItem.minDuration,
          hardStart: nextItem.hardStart,
          notes: nextItem.notes,
        );
      }

      _agenda = updatedAgenda;
      await NeonDatabaseService().updateAgendaTimingsBatch(_agenda, targetEventId: _event!.id);

      _event = EventModel(
        id: _event!.id,
        name: _event!.name,
        type: _event!.type,
        date: _event!.date,
        venue: _event!.venue,
        tone: _event!.tone,
        description: _event!.description,
        ownerId: _event!.ownerId,
        joinCode: _event!.joinCode,
        anchorIds: _event!.anchorIds,
        liveState: LiveStateModel(
          status: 'live',
          currentItemId: nextLiveId,
          startedAt: _event!.liveState.startedAt,
          totalDelayMin: _event!.liveState.totalDelayMin,
        ),
        createdAt: _event!.createdAt,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      try {
        if (currentSession != null) {
          await _neonService.completeAgendaItem(_event!.id, currentSession!.id);
        }
      } catch (_) {}
    }
    _isLoading = false;
    _safeNotifyListeners();
    return false;
  }

  Future<String?> generateAiScript(String type, {String? customContext}) async {
    if (_event == null) return null;
    try {
      final res = await _apiClient.post('/ai/generate', {
        'eventId': _event!.id,
        'type': type,
        'itemId': currentSession?.id,
        'customContext': customContext,
      });

      if (res.success && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        final script = ScriptModel(
          id: data['id'] ?? 'script-${DateTime.now().millisecondsSinceEpoch}',
          type: type,
          text: data['script'] ?? '',
          source: data['source'] ?? 'ai',
          provider: data['provider'],
          createdBy: 'ai',
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );
        _activeScript = script;
        _safeNotifyListeners();
        return script.text;
      }
    } catch (_) {}

    // Fallback Quad-AI script generator
    final session = currentSession;
    final speaker = currentSpeaker;
    final title = session?.title ?? 'Upcoming Stage Session';
    final speakerName = speaker?.name ?? 'our distinguished speaker';
    final org = speaker?.organization.isNotEmpty == true ? ' (${speaker!.organization})' : '';
    final topic = speaker?.topic.isNotEmpty == true ? ' discussing "${speaker!.topic}"' : '';

    String fallbackText = '';
    if (type == 'intro') {
      fallbackText = "Welcome ladies and gentlemen to $title. It is our immense pleasure to introduce $speakerName$org$topic. Please join us in welcoming $speakerName to the stage!";
    } else if (type == 'delay') {
      fallbackText = "Ladies and gentlemen, thank you for your patience. We are tuning our stage technical setup for $title. We will resume in just a few moments. Stay tuned!";
    } else {
      fallbackText = "Thank you $speakerName for that outstanding session on $title. Up next on stage, stay tuned as we transition to our next session!";
    }

    final script = ScriptModel(
      id: 'script-${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      text: fallbackText,
      source: 'local_quad_ai',
      provider: 'Quad-AI Fail-Safe Engine',
      createdBy: 'ai',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    _activeScript = script;
    notifyListeners();
    return script.text;
  }

  Future<bool> addSpeaker(SpeakerModel newSpeaker, {String? eventId, String? originalId}) async {
    _isLoading = true;
    notifyListeners();

    final targetId = eventId ?? _event?.id;
    String? neonSpeakerId;
    try {
      neonSpeakerId = await NeonDatabaseService().saveSpeaker(newSpeaker, targetEventId: targetId);
    } catch (e) {
      debugPrint("⚠️ Direct Neon DB speaker save error: $e");
    }

    final savedSpeaker = SpeakerModel(
      id: neonSpeakerId ?? newSpeaker.id,
      name: newSpeaker.name,
      designation: newSpeaker.designation,
      organization: newSpeaker.organization,
      topic: newSpeaker.topic,
      bio: newSpeaker.bio,
      highlights: newSpeaker.highlights,
      photoUrl: newSpeaker.photoUrl,
      status: newSpeaker.status,
    );

    final removeId = originalId ?? newSpeaker.id;
    _speakers.removeWhere((s) => s.id == removeId || s.id == savedSpeaker.id);
    _speakers.add(savedSpeaker);
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> deleteSpeaker(String speakerId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await NeonDatabaseService().deleteSpeaker(speakerId);
    } catch (e) {
      debugPrint("⚠️ Direct Neon DB speaker delete error: $e");
    }

    _speakers.removeWhere((s) => s.id == speakerId);
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> fetchSpeakers(String? eventId) async {
    try {
      final neonSpeakers = await NeonDatabaseService().getSpeakersForEvent(eventId);
      if (neonSpeakers.isNotEmpty) {
        final existingIds = neonSpeakers.map((s) => s.id).toSet();
        final localOnly = _speakers.where((s) => !existingIds.contains(s.id)).toList();
        _speakers = [...neonSpeakers, ...localOnly];
        notifyListeners();
      }
    } catch (e) {
      debugPrint("⚠️ Direct Neon DB fetch speakers error: $e");
    }
  }

  Future<void> fetchOrganizerEvents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // 1. Fetch directly from Neon PostgreSQL cloud database over TLS
    try {
      final neonEvents = await NeonDatabaseService().getEvents();
      if (neonEvents.isNotEmpty) {
        final existingIds = neonEvents.map((e) => e.id).toSet();
        final localOnly = _organizerEvents.where((e) => !existingIds.contains(e.id)).toList();
        _organizerEvents = [...neonEvents, ...localOnly];
      }
    } catch (e) {
      debugPrint("⚠️ Direct Neon DB event fetch error: $e");
    }

    // 2. Fallback to API server if empty
    if (_organizerEvents.isEmpty) {
      try {
        final res = await _apiClient.get('/events');
        if (res.success && res.data != null) {
          final list = res.data as List<dynamic>;
          _organizerEvents = list.map((e) => EventModel.fromJson(e as Map<String, dynamic>)).toList();
        }
      } catch (e) {
        _errorMessage = e.toString();
      }
    }

    if (_organizerEvents.isEmpty) {
      debugPrint("ℹ️ [EventProvider] No events found in Neon DB.");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createEvent(EventModel newEvent) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // 1. Direct cloud-native save into Neon PostgreSQL over TLS
    String? neonEventId;
    try {
      neonEventId = await NeonDatabaseService().saveEvent(newEvent);
    } catch (e) {
      debugPrint("⚠️ Neon DB direct save error: $e");
    }

    final savedEvent = EventModel(
      id: neonEventId ?? newEvent.id,
      name: newEvent.name,
      type: newEvent.type,
      date: newEvent.date,
      venue: newEvent.venue,
      tone: newEvent.tone,
      description: newEvent.description,
      ownerId: newEvent.ownerId,
      joinCode: newEvent.joinCode,
      anchorIds: newEvent.anchorIds,
      liveState: newEvent.liveState,
      createdAt: newEvent.createdAt,
    );

    // 2. Try sync to Node backend API if available
    try {
      await _apiClient.post('/events', savedEvent.toJson());
    } catch (_) {}

    // 3. Keep in active provider state so it's instantly visible in app UI
    _organizerEvents.removeWhere((e) => e.id == savedEvent.id);
    _organizerEvents.insert(0, savedEvent);
    _event = savedEvent;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  void selectEvent(EventModel selected) {
    _event = selected;
    loadEvent(selected.id);
  }

  Future<void> fetchAgenda(String? eventId) async {
    try {
      final rawList = await NeonDatabaseService().getAgendaForEvent(eventId);
      if (rawList.isNotEmpty) {
        _agenda = rawList.map((map) => AgendaItemModel.fromJson(map)).toList();
        notifyListeners();
      } else {
        _agenda = [];
        notifyListeners();
      }
    } catch (e) {
      debugPrint("⚠️ Direct Neon DB fetch agenda error: $e");
    }
  }

  Future<bool> addAgendaItem(AgendaItemModel newItem, {String? eventId, String? originalId}) async {
    _isLoading = true;
    notifyListeners();

    final targetId = eventId ?? _event?.id;
    String? neonAgendaId;
    try {
      neonAgendaId = await NeonDatabaseService().saveAgendaItem(newItem, targetEventId: targetId);
    } catch (e) {
      debugPrint("⚠️ Direct Neon DB agenda save error: $e");
    }

    final savedItem = AgendaItemModel(
      id: neonAgendaId ?? newItem.id,
      order: newItem.order,
      title: newItem.title,
      type: newItem.type,
      speakerIds: newItem.speakerIds,
      duration: newItem.duration,
      plannedStart: newItem.plannedStart,
      startTime: newItem.startTime,
      endTime: newItem.endTime,
      status: newItem.status,
      absorbable: newItem.absorbable,
      minDuration: newItem.minDuration,
      hardStart: newItem.hardStart,
      notes: newItem.notes,
    );

    final removeId = originalId ?? newItem.id;
    _agenda.removeWhere((it) => it.id == removeId || it.id == savedItem.id);
    _agenda.add(savedItem);
    _agenda.sort((a, b) => a.order.compareTo(b.order));

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> deleteAgendaItem(String itemId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await NeonDatabaseService().deleteAgendaItem(itemId);
    } catch (e) {
      debugPrint("⚠️ Direct Neon DB delete agenda error: $e");
    }

    _agenda.removeWhere((it) => it.id == itemId);
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> reorderAgenda(List<AgendaItemModel> newAgendaList) async {
    _agenda = newAgendaList;
    notifyListeners();

    for (int i = 0; i < _agenda.length; i++) {
      final updated = AgendaItemModel(
        id: _agenda[i].id,
        order: i + 1,
        title: _agenda[i].title,
        type: _agenda[i].type,
        speakerIds: _agenda[i].speakerIds,
        duration: _agenda[i].duration,
        plannedStart: _agenda[i].plannedStart,
        startTime: _agenda[i].startTime,
        endTime: _agenda[i].endTime,
        status: _agenda[i].status,
        absorbable: _agenda[i].absorbable,
        minDuration: _agenda[i].minDuration,
        hardStart: _agenda[i].hardStart,
        notes: _agenda[i].notes,
      );
      _agenda[i] = updated;
      try {
        await NeonDatabaseService().saveAgendaItem(updated, targetEventId: _event?.id);
      } catch (_) {}
    }
    notifyListeners();
    return true;
  }
}

