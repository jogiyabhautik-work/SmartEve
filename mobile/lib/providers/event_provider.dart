import 'dart:async';
import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../models/agenda_item_model.dart';
import '../models/event_model.dart';
import '../models/notification_model.dart';
import '../models/script_model.dart';
import '../models/speaker_model.dart';

class EventProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  EventModel? _event;
  List<AgendaItemModel> _agenda = [];
  List<SpeakerModel> _speakers = [];
  List<NotificationModel> _notifications = [];
  ScriptModel? _activeScript;

  bool _isLoading = false;
  String? _errorMessage;
  Timer? _tickerTimer;

  EventModel? get event => _event;
  List<AgendaItemModel> get agenda => _agenda;
  List<SpeakerModel> get speakers => _speakers;
  List<NotificationModel> get notifications => _notifications;
  ScriptModel? get activeScript => _activeScript;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  EventProvider() {
    _startTicker();
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    super.dispose();
  }

  void _startTicker() {
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_event?.liveState.status == 'live') {
        notifyListeners();
      }
    });
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
    notifyListeners();

    try {
      final eventRes = await _apiClient.get('/events/$eventId');
      if (eventRes.success && eventRes.data != null) {
        _event = EventModel.fromJson(eventRes.data as Map<String, dynamic>);
      }

      final agendaRes = await _apiClient.get('/events/$eventId/agenda');
      if (agendaRes.success && agendaRes.data != null) {
        final list = agendaRes.data as List<dynamic>;
        _agenda = list.map((e) => AgendaItemModel.fromJson(e as Map<String, dynamic>)).toList();
      }

      final speakersRes = await _apiClient.get('/events/$eventId/speakers');
      if (speakersRes.success && speakersRes.data != null) {
        final list = speakersRes.data as List<dynamic>;
        _speakers = list.map((e) => SpeakerModel.fromJson(e as Map<String, dynamic>)).toList();
      }

      final notifRes = await _apiClient.get('/events/$eventId/notifications');
      if (notifRes.success && notifRes.data != null) {
        final list = notifRes.data as List<dynamic>;
        _notifications = list.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
      }

      if (_event == null) {
        _seedFallbackData(eventId);
      }
    } catch (e) {
      _errorMessage = e.toString();
      _seedFallbackData(eventId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> startEvent() async {
    if (_event == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _apiClient.post('/events/${_event!.id}/start', {});
      if (res.success && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        if (data['event'] != null) {
          _event = EventModel.fromJson(data['event'] as Map<String, dynamic>);
        }
        if (data['agenda'] != null) {
          final list = data['agenda'] as List<dynamic>;
          _agenda = list.map((e) => AgendaItemModel.fromJson(e as Map<String, dynamic>)).toList();
        }
        if (data['notification'] != null) {
          _notifications.insert(0, NotificationModel.fromJson(data['notification'] as Map<String, dynamic>));
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> injectDelay(int minutes, {String? reason}) async {
    if (_event == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _apiClient.post('/events/${_event!.id}/delay', {
        'delayMinutes': minutes,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });

      if (res.success && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        if (data['event'] != null) {
          _event = EventModel.fromJson(data['event'] as Map<String, dynamic>);
        }
        if (data['reflow']?['items'] != null) {
          final list = data['reflow']['items'] as List<dynamic>;
          _agenda = list.map((e) => AgendaItemModel.fromJson(e as Map<String, dynamic>)).toList();
        }
        if (data['notification'] != null) {
          _notifications.insert(0, NotificationModel.fromJson(data['notification'] as Map<String, dynamic>));
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> completeCurrentSession() async {
    if (_event == null) return false;
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _apiClient.post('/events/${_event!.id}/complete-current', {});
      if (res.success && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        if (data['event'] != null) {
          _event = EventModel.fromJson(data['event'] as Map<String, dynamic>);
        }
        if (data['agenda'] != null) {
          final list = data['agenda'] as List<dynamic>;
          _agenda = list.map((e) => AgendaItemModel.fromJson(e as Map<String, dynamic>)).toList();
        }
        if (data['notification'] != null) {
          _notifications.insert(0, NotificationModel.fromJson(data['notification'] as Map<String, dynamic>));
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
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
        notifyListeners();
        return script.text;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    return null;
  }

  void _seedFallbackData(String eventId) {
    final now = DateTime.now();
    _event = EventModel(
      id: eventId,
      name: 'TechNova 2026 — AI Innovation Summit',
      type: 'Flagship AI Conference',
      date: '2026-09-19',
      venue: 'Main Auditorium, Hall A',
      tone: 'Visionary & Energetic',
      ownerId: 'organizer-1',
      joinCode: 'TN26',
      liveState: LiveStateModel(
        status: 'live',
        currentItemId: 'item-2',
        startedAt: now.millisecondsSinceEpoch - 1000 * 60 * 15,
        totalDelayMin: 0,
      ),
      createdAt: now.millisecondsSinceEpoch - 86400000,
    );

    _speakers = [
      SpeakerModel(
        id: 'spk-1',
        name: 'Dr. Aris Vance',
        designation: 'VP of Applied AI',
        organization: 'DeepScale Labs',
        topic: 'Autonomous Agents in High-Stakes Operations',
        bio: 'Pioneer in deterministic reasoning and mission-critical AI co-pilots.',
        status: 'arrived',
      ),
      SpeakerModel(
        id: 'spk-2',
        name: 'Priya Sharma',
        designation: 'Head of Distributed Systems',
        organization: 'QuantumCloud',
        topic: 'Sub-Millisecond Inference at Hyperscale',
        bio: 'Leads edge inference architecture serving 10M+ concurrent enterprise events.',
        status: 'arrived',
      ),
    ];

    _agenda = [
      AgendaItemModel(
        id: 'item-1',
        order: 1,
        title: 'Summit Opening & Housekeeping',
        type: 'opening',
        duration: 15,
        plannedStart: now.subtract(const Duration(minutes: 15)).toIso8601String(),
        startTime: now.subtract(const Duration(minutes: 15)).toIso8601String(),
        endTime: now.toIso8601String(),
        status: 'done',
      ),
      AgendaItemModel(
        id: 'item-2',
        order: 2,
        title: 'Keynote: Autonomous Agents in High-Stakes Operations',
        type: 'keynote',
        speakerIds: ['spk-1'],
        duration: 40,
        plannedStart: now.toIso8601String(),
        startTime: now.toIso8601String(),
        endTime: now.add(const Duration(minutes: 25)).toIso8601String(),
        status: 'live',
      ),
      AgendaItemModel(
        id: 'item-3',
        order: 3,
        title: 'Networking & Interactive Tea Break',
        type: 'break',
        duration: 30,
        absorbable: true,
        minDuration: 15,
        plannedStart: now.add(const Duration(minutes: 25)).toIso8601String(),
        startTime: now.add(const Duration(minutes: 25)).toIso8601String(),
        endTime: now.add(const Duration(minutes: 55)).toIso8601String(),
        status: 'upcoming',
      ),
    ];
  }
}
