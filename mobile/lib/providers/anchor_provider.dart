import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/services/neon_database_service.dart';
import '../models/anchor_dashboard_models.dart';

class AnchorProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final NeonDatabaseService _neonService = NeonDatabaseService();
  bool _isLoadingBackend = false;
  String _searchQuery = '';
  bool _isViewAllUpcoming = false;
  int _unreadAiAlertCount = 2;
  bool _isDisposed = false;

  bool get isLoadingBackend => _isLoadingBackend;

  AnchorProvider({bool autoFetch = true}) {
    if (autoFetch) {
      fetchDashboardFromBackend();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  /// Guards async completions that land after the provider was disposed
  /// (e.g. the screen was popped while the dashboard fetch was in flight).
  void _safeNotifyListeners() {
    if (_isDisposed) return;
    notifyListeners();
  }

  // Sticky Event Invitations (Updated live from Neon DB / API backend)
  final List<AnchorInvitation> _invitations = [];

  // Upcoming Events (Updated live from Neon DB / API backend)
  final List<AnchorEventCardItem> _upcomingEvents = [];

  // Completed Events (Updated live from Neon DB / API backend)
  final List<AnchorEventCardItem> _completedEvents = [];

  // Getters
  String get searchQuery => _searchQuery;
  bool get isViewAllUpcoming => _isViewAllUpcoming;
  int get unreadAiAlertCount => _unreadAiAlertCount;

  List<AnchorInvitation> get invitations => _invitations;
  List<AnchorEventCardItem> get upcomingEvents => _upcomingEvents;
  List<AnchorEventCardItem> get completedEvents => _completedEvents;

  List<AnchorInvitation> get filteredInvitations {
    if (_searchQuery.trim().isEmpty) return _invitations;
    final q = _searchQuery.toLowerCase();
    return _invitations.where((inv) {
      return inv.title.toLowerCase().contains(q) ||
          inv.organizerName.toLowerCase().contains(q) ||
          inv.collegeName.toLowerCase().contains(q) ||
          inv.date.toLowerCase().contains(q);
    }).toList();
  }

  List<AnchorEventCardItem> get filteredUpcomingEvents {
    if (_searchQuery.trim().isEmpty) return _upcomingEvents;
    final q = _searchQuery.toLowerCase();
    return _upcomingEvents.where((e) {
      return e.title.toLowerCase().contains(q) ||
          e.organizerName.toLowerCase().contains(q) ||
          e.collegeName.toLowerCase().contains(q) ||
          e.date.toLowerCase().contains(q);
    }).toList();
  }

  List<AnchorEventCardItem> get displayedUpcomingEvents {
    final list = filteredUpcomingEvents;
    if (_isViewAllUpcoming || list.length <= 3) {
      return list;
    }
    return list.sublist(0, 3);
  }

  List<AnchorEventCardItem> get filteredCompletedEvents {
    if (_searchQuery.trim().isEmpty) return _completedEvents;
    final q = _searchQuery.toLowerCase();
    return _completedEvents.where((e) {
      return e.title.toLowerCase().contains(q) ||
          e.organizerName.toLowerCase().contains(q) ||
          e.collegeName.toLowerCase().contains(q) ||
          e.date.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> fetchDashboardFromBackend() async {
    _isLoadingBackend = true;
    _safeNotifyListeners();
    try {
      final res = await _apiClient.get('/anchor/dashboard');
      if (res.success && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        _populateFromData(data);
      } else {
        // Fallback to direct Neon database connection
        final dbData = await _neonService.getAnchorDashboardData();
        if (dbData.isNotEmpty) {
          _populateFromData(dbData);
        }
      }
    } catch (_) {
      try {
        final dbData = await _neonService.getAnchorDashboardData();
        if (dbData.isNotEmpty) {
          _populateFromData(dbData);
        }
      } catch (_) {}
    } finally {
      _isLoadingBackend = false;
      _safeNotifyListeners();
    }
  }

  void _populateFromData(Map<String, dynamic> data) {
    if (data['invitations'] is List) {
      _invitations.clear();
      for (final inv in data['invitations']) {
        if (inv is Map<String, dynamic>) {
          _invitations.add(AnchorInvitation.fromJson(inv));
        }
      }
    }
    if (data['upcomingEvents'] is List) {
      _upcomingEvents.clear();
      for (final ev in data['upcomingEvents']) {
        if (ev is Map<String, dynamic>) {
          _upcomingEvents.add(AnchorEventCardItem(
            id: ev['id']?.toString() ?? '',
            title: ev['title']?.toString() ?? '',
            eventType: ev['eventType']?.toString() ?? 'Conference',
            date: ev['date']?.toString() ?? '',
            time: ev['time']?.toString() ?? '',
            organizerName: ev['organizerName']?.toString() ?? '',
            collegeName: ev['collegeName']?.toString() ?? '',
            status: _parseStatus(ev['status']),
            joinCode: ev['joinCode']?.toString() ?? 'EV26',
            venue: ev['venue']?.toString() ?? 'Main Stage',
            duration: ev['duration']?.toString() ?? '3h 00m',
          ));
        }
      }
    }
    if (data['completedEvents'] is List) {
      _completedEvents.clear();
      for (final ev in data['completedEvents']) {
        if (ev is Map<String, dynamic>) {
          _completedEvents.add(AnchorEventCardItem(
            id: ev['id']?.toString() ?? '',
            title: ev['title']?.toString() ?? '',
            eventType: ev['eventType']?.toString() ?? 'Conference',
            date: ev['date']?.toString() ?? '',
            time: ev['time']?.toString() ?? '',
            organizerName: ev['organizerName']?.toString() ?? '',
            collegeName: ev['collegeName']?.toString() ?? '',
            status: AnchorEventStatus.completed,
            joinCode: ev['joinCode']?.toString() ?? 'EV26',
            venue: ev['venue']?.toString() ?? 'Main Stage',
            duration: ev['duration']?.toString() ?? '3h 00m',
            recapSummary: ev['recapSummary']?.toString() ?? 'Stage session concluded successfully.',
          ));
        }
      }
    }
    if (data['unreadAiAlertCount'] != null) {
      _unreadAiAlertCount = int.tryParse(data['unreadAiAlertCount'].toString()) ?? 0;
    }
  }

  Future<void> acceptInvitation(String invitationId) async {
    final idx = _invitations.indexWhere((i) => i.id == invitationId || i.eventId == invitationId);
    if (idx != -1) {
      final inv = _invitations[idx];
      _invitations.removeAt(idx);
      
      _upcomingEvents.insert(0, AnchorEventCardItem(
        id: inv.eventId,
        title: inv.title,
        eventType: inv.eventType,
        date: inv.date,
        time: inv.time,
        organizerName: inv.organizerName,
        collegeName: inv.collegeName,
        status: AnchorEventStatus.accepted,
        joinCode: 'EV26',
        venue: inv.venue,
        duration: '3h 00m',
      ));
      
      _safeNotifyListeners();
      
      try {
        await _neonService.updateInvitationStatus(inv.id, 'accepted');
      } catch (e) {
        debugPrint('Failed to update invitation status in DB: $e');
      }
    }
  }

  Future<void> declineInvitation(String invitationId) async {
    final idx = _invitations.indexWhere((i) => i.id == invitationId || i.eventId == invitationId);
    if (idx != -1) {
      final inv = _invitations[idx];
      _invitations.removeAt(idx);
      _safeNotifyListeners();
      
      try {
        await _neonService.updateInvitationStatus(inv.id, 'declined');
      } catch (e) {
        debugPrint('Failed to update invitation status in DB: $e');
      }
    }
  }

  AnchorEventStatus _parseStatus(dynamic val) {
    switch (val?.toString().toLowerCase()) {
      case 'active':
      case 'live':
        return AnchorEventStatus.active;
      case 'accepted':
        return AnchorEventStatus.accepted;
      case 'completed':
        return AnchorEventStatus.completed;
      default:
        return AnchorEventStatus.invited;
    }
  }

  // Actions
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void toggleViewAllUpcoming() {
    _isViewAllUpcoming = !_isViewAllUpcoming;
    notifyListeners();
  }

  void clearAiAlerts() {
    _unreadAiAlertCount = 0;
    notifyListeners();
  }
}
