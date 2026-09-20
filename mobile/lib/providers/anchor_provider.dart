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

  // Sticky Event Invitations (Seeded default, updated live from backend)
  final List<AnchorInvitation> _invitations = [
    const AnchorInvitation(
      id: 'inv_1',
      eventId: 'evt_gdg_1',
      title: 'GDG DevFest Annual Tech Keynote',
      eventType: 'Conference',
      organizerName: 'Sarah Jenkins',
      collegeName: 'Stanford Engineering Hub',
      date: 'Oct 24, 2026',
      time: '10:00 AM - 01:00 PM',
      invitedAt: '10m ago',
      venue: 'Main Auditorium A',
      description: 'Annual flagship developer conference keynote and open stage emcee.',
    ),
    const AnchorInvitation(
      id: 'inv_2',
      eventId: 'evt_hack_2',
      title: 'AI Innovators Global Hackathon Finals',
      eventType: 'Hackathon',
      organizerName: 'Marcus Vance',
      collegeName: 'MIT Media Lab',
      date: 'Nov 02, 2026',
      time: '02:00 PM - 06:00 PM',
      invitedAt: '1h ago',
      venue: 'Grand Ballroom',
      description: 'Host final pitching rounds and live awards presentation ceremony.',
    ),
  ];

  // Upcoming Events (Seeded default, updated live from backend)
  final List<AnchorEventCardItem> _upcomingEvents = [
    const AnchorEventCardItem(
      id: 'up_1',
      title: 'TechNova Live Summit 2026',
      eventType: 'Tech Summit',
      date: 'Oct 28, 2026',
      time: '09:00 AM - 12:00 PM',
      organizerName: 'Alex Rivera',
      collegeName: 'TechNova Convention Center',
      status: AnchorEventStatus.accepted,
      joinCode: 'CNS26',
      venue: 'Hall B',
      duration: '3h 00m',
    ),
    const AnchorEventCardItem(
      id: 'up_2',
      title: 'Quantum Computing Symposium',
      eventType: 'Symposium',
      date: 'Nov 05, 2026',
      time: '11:00 AM - 02:00 PM',
      organizerName: 'Elena Rostova',
      collegeName: 'Oxford Institute',
      status: AnchorEventStatus.active,
      joinCode: 'QCS26',
      venue: 'Virtual Stage 1',
      duration: '3h 00m',
    ),
    const AnchorEventCardItem(
      id: 'up_3',
      title: 'NextGen Robotics Showcase',
      eventType: 'Showcase',
      date: 'Nov 12, 2026',
      time: '01:00 PM - 04:00 PM',
      organizerName: 'David Chen',
      collegeName: 'Carnegie Mellon Hall',
      status: AnchorEventStatus.accepted,
      joinCode: 'NRS26',
      venue: 'Expo Arena',
      duration: '3h 00m',
    ),
    const AnchorEventCardItem(
      id: 'up_4',
      title: 'CyberSecurity Leadership Forum',
      eventType: 'Forum',
      date: 'Nov 18, 2026',
      time: '03:00 PM - 06:00 PM',
      organizerName: 'Sophia Taylor',
      collegeName: 'Columbia University',
      status: AnchorEventStatus.accepted,
      joinCode: 'CLF26',
      venue: 'Auditorium 3',
      duration: '3h 00m',
    ),
  ];

  // Completed Events (Seeded default, updated live from backend)
  final List<AnchorEventCardItem> _completedEvents = [
    const AnchorEventCardItem(
      id: 'comp_1',
      title: 'Silicon Valley AI Mixer',
      eventType: 'Networking',
      date: 'Sep 15, 2026',
      time: '06:00 PM - 09:00 PM',
      organizerName: 'Priya Sharma',
      collegeName: 'San Jose Civic',
      status: AnchorEventStatus.completed,
      joinCode: 'SVM26',
      venue: 'Skyline Lounge',
      duration: '3h 00m',
      recapSummary: 'Over 300 tech founders and investors connected seamlessly.',
    ),
    const AnchorEventCardItem(
      id: 'comp_2',
      title: 'FullStack Developer Day',
      eventType: 'Workshop',
      date: 'Sep 02, 2026',
      time: '10:00 AM - 04:00 PM',
      organizerName: 'Jordan Hayes',
      collegeName: 'DevHub NYC',
      status: AnchorEventStatus.completed,
      joinCode: 'FSD26',
      venue: 'Workshop Studio',
      duration: '6h 00m',
      recapSummary: 'Interactive hands-on session with 98% attendee satisfaction.',
    ),
    const AnchorEventCardItem(
      id: 'comp_3',
      title: 'FinTech Revolution Conference',
      eventType: 'Conference',
      date: 'Aug 20, 2026',
      time: '09:00 AM - 05:00 PM',
      organizerName: 'Arthur Dent',
      collegeName: 'London School of Economics',
      status: AnchorEventStatus.completed,
      joinCode: 'FTR26',
      venue: 'Grand Hall',
      duration: '8h 00m',
      recapSummary: 'Keynote panels delivered on schedule with dynamic emcee pacing.',
    ),
  ];

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
        if (dbData != null && dbData.isNotEmpty) {
          _populateFromData(dbData);
        }
      }
    } catch (_) {
      try {
        final dbData = await _neonService.getAnchorDashboardData();
        if (dbData != null && dbData.isNotEmpty) {
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

  Future<void> acceptInvitation(String id) async {
    final index = _invitations.indexWhere((inv) => inv.id == id);
    if (index != -1) {
      final inv = _invitations[index];
      _invitations.removeAt(index);

      // Add to upcoming events as 'accepted'
      _upcomingEvents.insert(
        0,
        AnchorEventCardItem(
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
          duration: 'TBD',
        ),
      );
      notifyListeners();

      try {
        final res = await _apiClient.post('/anchor/invitations/$id/accept', {});
        if (!res.success) {
          await _neonService.updateInvitationStatus(id, 'accepted');
        }
      } catch (_) {
        try {
          await _neonService.updateInvitationStatus(id, 'accepted');
        } catch (_) {}
      }
    }
  }

  Future<void> declineInvitation(String id) async {
    _invitations.removeWhere((inv) => inv.id == id);
    notifyListeners();

    try {
      final res = await _apiClient.post('/anchor/invitations/$id/decline', {});
      if (!res.success) {
        await _neonService.updateInvitationStatus(id, 'rejected');
      }
    } catch (_) {
      try {
        await _neonService.updateInvitationStatus(id, 'rejected');
      } catch (_) {}
    }
  }

  void clearAiAlerts() {
    _unreadAiAlertCount = 0;
    notifyListeners();
  }
}
