import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../models/script_model.dart';

enum ScriptSortOption {
  timeAsc,
  timeDesc,
  byType,
  recentlyUpdated,
}

class ScriptsProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final String _eventId = 'technova-2026';

  List<ScriptModel> _scripts = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Filter & Search states
  String _searchQuery = '';
  String _selectedFilter = 'all'; // 'all', 'opening', 'speaker_intro', 'transition', 'closing', 'announcement'
  ScriptSortOption _sortOption = ScriptSortOption.timeAsc;

  // Real-time toast/notification stream for live organizer updates
  String? _latestToastNotification;

  // Activity audit log for Organizer Connection Hub
  final List<Map<String, dynamic>> _organizerActivityLog = [];

  // Admin analytics cache
  Map<String, dynamic>? _adminAnalytics;

  // Getters
  List<ScriptModel> get scripts => _scripts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedFilter => _selectedFilter;
  ScriptSortOption get sortOption => _sortOption;
  String? get latestToastNotification => _latestToastNotification;
  List<Map<String, dynamic>> get organizerActivityLog => List.unmodifiable(_organizerActivityLog);
  Map<String, dynamic>? get adminAnalytics => _adminAnalytics;

  ScriptsProvider() {
    loadScripts();
  }

  void clearToast() {
    _latestToastNotification = null;
    notifyListeners();
  }

  // --- Search & Filter Mutators ---
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  void setSortOption(ScriptSortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  // --- Dynamic Filtering & Sorting ---
  List<ScriptModel> get filteredScripts {
    List<ScriptModel> list = List.from(_scripts);

    // 1. Filter by category
    if (_selectedFilter != 'all') {
      list = list.where((s) {
        if (_selectedFilter == 'announcements') {
          return s.type == 'announcement';
        }
        return s.type == _selectedFilter;
      }).toList();
    }

    // 2. Search query matching
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((s) {
        final matchesTitle = s.title.toLowerCase().contains(q);
        final matchesSpeaker = s.speakerName?.toLowerCase().contains(q) ?? false;
        final matchesType = s.typeLabel.toLowerCase().contains(q);
        final matchesTone = s.tone?.toLowerCase().contains(q) ?? false;
        final matchesText = s.text.toLowerCase().contains(q);
        return matchesTitle || matchesSpeaker || matchesType || matchesTone || matchesText;
      }).toList();
    }

    // 3. Sort
    switch (_sortOption) {
      case ScriptSortOption.timeAsc:
        list.sort((a, b) => _compareTimeSlots(a.timeSlot, b.timeSlot, true));
        break;
      case ScriptSortOption.timeDesc:
        list.sort((a, b) => _compareTimeSlots(a.timeSlot, b.timeSlot, false));
        break;
      case ScriptSortOption.byType:
        list.sort((a, b) => _typeRank(a.type).compareTo(_typeRank(b.type)));
        break;
      case ScriptSortOption.recentlyUpdated:
        list.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
        break;
    }

    return list;
  }

  int _typeRank(String type) {
    switch (type) {
      case 'opening':
        return 1;
      case 'speaker_intro':
        return 2;
      case 'transition':
        return 3;
      case 'announcement':
        return 4;
      case 'closing':
        return 5;
      default:
        return 6;
    }
  }

  int _compareTimeSlots(String? a, String? b, bool ascending) {
    if (a == null && b == null) return 0;
    if (a == null) return ascending ? 1 : -1;
    if (b == null) return ascending ? -1 : 1;
    return ascending ? a.compareTo(b) : b.compareTo(a);
  }

  int getCountForFilter(String filterKey) {
    if (filterKey == 'all') return _scripts.length;
    final target = filterKey == 'announcements' ? 'announcement' : filterKey;
    return _scripts.where((s) => s.type == target).length;
  }

  // --- Next / Current Script for Bottom Sticky Display ---
  ScriptModel? get nextScript {
    if (_scripts.isEmpty) return null;
    // Prefer the first unreviewed or upcoming script in order
    final unreviewed = _scripts.where((s) => !s.isReviewedByAnchor).toList();
    if (unreviewed.isNotEmpty) return unreviewed.first;
    return _scripts.first;
  }

  // --- Backend Sync: Load Scripts ---
  Future<void> loadScripts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiClient.get('/events/$_eventId/scripts');
      if (res.success && res.data != null && res.data is List) {
        final list = (res.data as List)
            .map((item) => ScriptModel.fromJson(item as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) {
          _scripts = list;
          _isLoading = false;
          notifyListeners();
          fetchAdminAnalytics();
          return;
        }
      }
    } catch (_) {
      // Graceful fallback to seeded initial scripts
    }

    // Seed realistic fallback data if backend is starting or offline
    _scripts = _getSeededScripts();
    _isLoading = false;
    notifyListeners();
    fetchAdminAnalytics();
  }

  // --- Anchor Actions: View, Review, Modify ---
  Future<void> markScriptAsViewed(String scriptId) async {
    final idx = _scripts.indexWhere((s) => s.id == scriptId);
    if (idx == -1) return;

    final script = _scripts[idx];
    final updated = script.copyWith(
      viewedByAnchor: true,
      viewedAt: DateTime.now().millisecondsSinceEpoch,
      usageCount: script.usageCount + 1,
    );
    _scripts[idx] = updated;

    _logOrganizerActivity(
      type: 'viewed',
      title: 'Anchor viewed script',
      detail: 'Anchor opened "${updated.title}" (${updated.typeLabel})',
      scriptId: scriptId,
    );

    notifyListeners();

    // Async sync to backend
    try {
      await _apiClient.patch('/events/$_eventId/scripts/$scriptId', {
        'viewedByAnchor': true,
        'viewedAt': updated.viewedAt,
        'usageCount': updated.usageCount,
      });
    } catch (_) {}
  }

  Future<void> toggleScriptReviewed(String scriptId) async {
    final idx = _scripts.indexWhere((s) => s.id == scriptId);
    if (idx == -1) return;

    final script = _scripts[idx];
    final nextState = !script.isReviewedByAnchor;
    final updated = script.copyWith(
      isReviewedByAnchor: nextState,
      lastUpdated: DateTime.now().millisecondsSinceEpoch,
    );
    _scripts[idx] = updated;

    _logOrganizerActivity(
      type: 'reviewed',
      title: nextState ? 'Anchor marked script as reviewed' : 'Anchor unmarked script review',
      detail: '"${updated.title}" sign-off status changed to ${nextState ? "Approved" : "Pending"}',
      scriptId: scriptId,
    );

    notifyListeners();

    try {
      await _apiClient.patch('/events/$_eventId/scripts/$scriptId', {
        'isReviewedByAnchor': nextState,
      });
    } catch (_) {}
  }

  Future<bool> requestModification({
    required String scriptId,
    required String feedbackNote,
    String priority = 'medium',
    String anchorName = 'Jordan Hayes',
  }) async {
    final idx = _scripts.indexWhere((s) => s.id == scriptId);
    if (idx == -1) return false;

    final script = _scripts[idx];
    final req = ScriptModificationRequest(
      id: 'req-${DateTime.now().millisecondsSinceEpoch}',
      scriptId: scriptId,
      anchorName: anchorName,
      feedbackNote: feedbackNote,
      priority: priority,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      status: 'pending',
    );

    final updated = script.copyWith(
      status: 'revised',
      isUpdated: true,
      lastUpdated: DateTime.now().millisecondsSinceEpoch,
      modificationRequests: [req, ...script.modificationRequests],
    );
    _scripts[idx] = updated;

    _logOrganizerActivity(
      type: 'requested_change',
      title: 'Anchor requested change',
      detail: 'Priority $priority: "$feedbackNote" on "${updated.title}"',
      scriptId: scriptId,
    );

    _latestToastNotification = 'Modification request sent to Organizer (${priority.toUpperCase()})';
    notifyListeners();

    try {
      await _apiClient.post('/events/$_eventId/scripts/$scriptId/modify-request', {
        'anchorName': anchorName,
        'feedbackNote': feedbackNote,
        'priority': priority,
      });
      return true;
    } catch (_) {
      return true;
    }
  }

  // --- SmartEve AI Assistant Actions ---
  Future<String?> generateAiAssistance({
    required String scriptId,
    required String customPrompt,
    String? quickAction,
  }) async {
    final script = _scripts.firstWhere((s) => s.id == scriptId, orElse: () => _scripts.first);

    // Build context prompt
    String fullPrompt = customPrompt;
    if (quickAction != null) {
      switch (quickAction) {
        case 'Make it shorter':
          fullPrompt = 'Condense and shorten the following script to under 35 words while preserving the main message and high stage energy: "${script.text}"';
          break;
        case 'Make it more engaging':
          fullPrompt = 'Make the following stage intro punchier, captivating, and emotionally engaging with rhetorical hooks: "${script.text}"';
          break;
        case 'Add humor':
          fullPrompt = 'Add a tasteful, witty, stage-friendly lighthearted humor line to the following anchor script: "${script.text}"';
          break;
        case 'Explain more':
          fullPrompt = 'Expand this stage script with deeper context on the speaker achievements and topic relevance: "${script.text}"';
          break;
      }
    }

    try {
      final res = await _apiClient.post('/ai/generate', {
        'eventId': _eventId,
        'type': script.type,
        'itemId': script.itemId,
        'tone': script.tone ?? 'Motivational',
        'customContext': fullPrompt,
      });

      if (res.success && res.data != null && res.data['script'] != null) {
        return res.data['script'] as String;
      }
    } catch (_) {}

    // Fallback AI simulation if offline
    return _simulateOfflineAiResponse(script.text, quickAction ?? customPrompt);
  }

  void applyRegeneratedScript(String scriptId, String newText) {
    final idx = _scripts.indexWhere((s) => s.id == scriptId);
    if (idx == -1) return;

    final script = _scripts[idx];
    final updated = script.copyWith(
      text: newText,
      version: script.version + 1,
      isUpdated: true,
      lastUpdated: DateTime.now().millisecondsSinceEpoch,
    );
    _scripts[idx] = updated;

    _logOrganizerActivity(
      type: 'ai_applied',
      title: 'SmartEve AI Script Applied',
      detail: 'Script "${updated.title}" updated via SmartEve AI Assist (v${updated.version})',
      scriptId: scriptId,
    );

    _latestToastNotification = 'SmartEve AI script applied successfully!';
    notifyListeners();

    try {
      _apiClient.patch('/events/$_eventId/scripts/$scriptId', {
        'text': newText,
        'version': updated.version,
        'isUpdated': true,
      });
    } catch (_) {}
  }

  // --- Real-Time Simulation: Organizer and Admin Actions ---
  void simulateOrganizerPushNewScript() {
    final newScript = ScriptModel(
      id: 'script-live-${DateTime.now().millisecondsSinceEpoch}',
      type: 'announcement',
      title: 'Urgent Stage Announcement: VIP Arrival in Hall C',
      timeSlot: '11:30 AM - 11:35 AM',
      durationMinutes: 5,
      status: 'pending',
      text:
          'Special announcement for all attendees: Our keynote panel on Autonomous Robotics will feature a live satellite link with our international research partners. Please settle into the main hall.',
      tone: 'Formal',
      targetAudience: 'All Attendees',
      organizerApprovedName: 'Alex Rivera (Lead Organizer)',
      source: 'manual',
      provider: 'manual',
      version: 1,
      createdBy: 'organizer',
      createdAt: DateTime.now().millisecondsSinceEpoch,
      isNew: true,
      isUpdated: false,
    );

    _scripts.insert(0, newScript);
    _latestToastNotification = 'New stage script published by Organizer: "${newScript.title}"';

    _logOrganizerActivity(
      type: 'organizer_push',
      title: 'Organizer created new script',
      detail: 'Published "${newScript.title}" with NEW badge',
      scriptId: newScript.id,
    );

    notifyListeners();
  }

  void simulateOrganizerReviseScript(String scriptId) {
    final idx = _scripts.indexWhere((s) => s.id == scriptId);
    if (idx == -1) return;

    final script = _scripts[idx];
    final updated = script.copyWith(
      text:
          '${script.text}\n\n[Organizer Note: Emphasize the interactive live Q&A via QR code during this segment.]',
      version: script.version + 1,
      isUpdated: true,
      isNew: false,
      status: 'revised',
      lastUpdated: DateTime.now().millisecondsSinceEpoch,
    );
    _scripts[idx] = updated;

    _latestToastNotification = 'Organizer updated script: "${updated.title}" (UPDATED badge applied)';

    _logOrganizerActivity(
      type: 'organizer_revised',
      title: 'Organizer pushed revised script',
      detail: 'Sent revision for "${updated.title}" with "Updated" notification',
      scriptId: scriptId,
    );

    notifyListeners();
  }

  Future<void> fetchAdminAnalytics() async {
    try {
      final res = await _apiClient.get('/events/$_eventId/scripts/analytics');
      if (res.success && res.data != null) {
        _adminAnalytics = res.data as Map<String, dynamic>;
        notifyListeners();
        return;
      }
    } catch (_) {}

    // Fallback analytics calculation
    final totalScripts = _scripts.length;
    final reviewedCount = _scripts.where((s) => s.isReviewedByAnchor).length;
    final reviewRate = totalScripts > 0 ? ((reviewedCount / totalScripts) * 100).round() : 0;
    final totalWords = _scripts.fold<int>(0, (sum, s) => sum + s.wordCount);
    final sortedByUsage = [..._scripts]..sort((a, b) => b.usageCount.compareTo(a.usageCount));

    _adminAnalytics = {
      'totalScripts': totalScripts,
      'reviewedCount': reviewedCount,
      'reviewRate': reviewRate,
      'totalWords': totalWords,
      'mostUsed': sortedByUsage.take(3).map((s) => {'title': s.title, 'count': s.usageCount, 'type': s.type}).toList(),
    };
    notifyListeners();
  }

  void _logOrganizerActivity({
    required String type,
    required String title,
    required String detail,
    required String scriptId,
  }) {
    final entry = {
      'id': 'log-${DateTime.now().millisecondsSinceEpoch}',
      'type': type,
      'title': title,
      'detail': detail,
      'scriptId': scriptId,
      'time': _formatCurrentTime(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    _organizerActivityLog.insert(0, entry);
  }

  String _formatCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _simulateOfflineAiResponse(String original, String prompt) {
    if (prompt.toLowerCase().contains('shorter')) {
      return 'Ladies and gentlemen, please join me in welcoming our visionary speaker on stage. Put your hands together for an extraordinary session!';
    }
    if (prompt.toLowerCase().contains('engaging')) {
      return 'Are you ready for the breakthrough of TechNova 2026? What you are about to hear redefined modern engineering. Please give the warmest ovation to our keynote guest!';
    }
    if (prompt.toLowerCase().contains('humor')) {
      return 'They say coffee fuels coders, but our next speaker fuels entire cloud clusters without breaking a sweat! Give it up for our brilliant keynote guest!';
    }
    return 'Good morning everyone! Please welcome our keynote speaker as we dive straight into cutting-edge technology and future innovations!';
  }

  List<ScriptModel> _getSeededScripts() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return [
      ScriptModel(
        id: 'script-1',
        type: 'opening',
        title: 'Opening',
        timeSlot: '09:30 AM - 09:45 AM',
        durationMinutes: 15,
        status: 'approved',
        itemId: 'item-1',
        text:
            'Good morning, innovators, creators, and leaders! Welcome to TechNova 2026 — the international summit on deterministic intelligence and autonomous systems. Today, we bring together over 1,200 forward-thinking technologists from 24 countries under one roof. Prepare for groundbreaking discoveries, deep-dive architectural breakthroughs, and high-energy stage demonstrations. Let us declare TechNova 2026 officially open!',
        tone: 'Motivational',
        targetAudience: 'Tech Leaders & Engineers',
        organizerApprovedName: 'Alex Rivera (Lead Organizer)',
        organizerApprovedAvatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=120',
        source: 'ai',
        provider: 'gemini',
        version: 1,
        createdBy: 'organizer',
        createdAt: now - 3600000 * 2,
        lastUpdated: now - 3600000 * 2,
        isNew: false,
        isUpdated: false,
        isReviewedByAnchor: true,
        viewedByAnchor: true,
        viewedAt: now - 3600000,
        usageCount: 3,
      ),
      ScriptModel(
        id: 'script-2',
        type: 'speaker_intro',
        title: 'Dr. Aris Vance',
        speakerName: 'Dr. Aris Vance',
        timeSlot: '09:45 AM - 10:25 AM',
        durationMinutes: 40,
        status: 'approved',
        itemId: 'item-2',
        text:
            'Our first keynote speaker today is a true pioneer in deterministic reasoning and mission-critical AI co-pilots. As Vice President of Applied AI at DeepScale Labs and former Head of Research at AI Frontier, he has spearheaded frameworks powering millions of sub-second decisions. Please give a thunderous TechNova welcome to Dr. Aris Vance!',
        tone: 'Formal',
        targetAudience: 'Enterprise Architects',
        organizerApprovedName: 'Alex Rivera (Lead Organizer)',
        organizerApprovedAvatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=120',
        source: 'ai',
        provider: 'gemini',
        version: 1,
        createdBy: 'organizer',
        createdAt: now - 3600000,
        lastUpdated: now - 3600000,
        isNew: false,
        isUpdated: false,
        isReviewedByAnchor: true,
        viewedByAnchor: true,
        viewedAt: now - 1800000,
        usageCount: 5,
      ),
      ScriptModel(
        id: 'script-3',
        type: 'transition',
        title: 'Transition',
        timeSlot: '10:25 AM - 10:40 AM',
        durationMinutes: 15,
        status: 'approved',
        itemId: 'item-3',
        text:
            'Thank you Dr. Vance for that visionary keynote on autonomous agent resilience. Up next, we are taking a brief 15-minute interactive networking pause. Refreshments and specialty coffee are served in the Grand Atrium. Be sure to explore the live demo booths and rejoin us here at 10:40 AM sharp for Priya Sharma\'s hyperscale infrastructure deep-dive!',
        tone: 'Casual',
        targetAudience: 'All Attendees',
        organizerApprovedName: 'Alex Rivera (Lead Organizer)',
        organizerApprovedAvatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=120',
        source: 'ai',
        provider: 'groq',
        version: 1,
        createdBy: 'organizer',
        createdAt: now - 1800000,
        lastUpdated: now - 1800000,
        isNew: false,
        isUpdated: false,
        isReviewedByAnchor: false,
        viewedByAnchor: true,
        viewedAt: now - 900000,
        usageCount: 2,
      ),
      ScriptModel(
        id: 'script-4',
        type: 'speaker_intro',
        title: 'Priya Sharma',
        speakerName: 'Priya Sharma',
        timeSlot: '10:40 AM - 11:15 AM',
        durationMinutes: 35,
        status: 'revised',
        itemId: 'item-4',
        text:
            'Welcome back everyone. Our next keynote speaker is renowned for engineering high-concurrency systems that withstand staggering scale. As Head of Distributed Systems at QuantumCloud and an ACM Distinguished Engineer, she oversees global edge clusters processing 10 million concurrent operations. Put your hands together for Priya Sharma!',
        tone: 'Visionary',
        targetAudience: 'Cloud & Distributed Engineers',
        organizerApprovedName: 'Alex Rivera (Lead Organizer)',
        organizerApprovedAvatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=120',
        source: 'ai',
        provider: 'gemini',
        version: 2,
        createdBy: 'organizer',
        createdAt: now - 1200000,
        lastUpdated: now - 300000,
        isNew: false,
        isUpdated: true,
        isReviewedByAnchor: false,
        viewedByAnchor: false,
        usageCount: 1,
      ),
      ScriptModel(
        id: 'script-5',
        type: 'announcement',
        title: 'Main Stage Audio Optimization & Stage Schedule Notice',
        timeSlot: '11:15 AM - 11:20 AM',
        durationMinutes: 5,
        status: 'pending',
        text:
            'Attention attendees and stage crew: Due to an interactive live demo in Hall B, we have synchronized our downstream agenda with an additional 5-minute safety buffer. Please take advantage of the QR codes at your seats for live interactive Q&A submission during the upcoming panel discussion.',
        tone: 'Formal',
        targetAudience: 'All Attendees & Crew',
        organizerApprovedName: 'Sarah Jenkins (Stage Manager)',
        organizerApprovedAvatarUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=120',
        source: 'manual',
        provider: 'manual',
        version: 1,
        createdBy: 'organizer',
        createdAt: now - 600000,
        lastUpdated: now - 600000,
        isNew: true,
        isUpdated: false,
        isReviewedByAnchor: false,
        viewedByAnchor: false,
        usageCount: 0,
      ),
      ScriptModel(
        id: 'script-6',
        type: 'closing',
        title: 'Closing',
        timeSlot: '12:50 PM - 01:05 PM',
        durationMinutes: 15,
        status: 'approved',
        itemId: 'item-7',
        text:
            'What an unforgettable journey of ideas, collaboration, and inspiration today at TechNova 2026. On behalf of the organizing committee, our stellar keynote speakers, and our partners, we thank each and every one of you for being part of this remarkable stage. Let us take these insights into the future. Safe travels, and see you next year!',
        tone: 'Motivational',
        targetAudience: 'All Attendees',
        organizerApprovedName: 'Alex Rivera (Lead Organizer)',
        organizerApprovedAvatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=120',
        source: 'ai',
        provider: 'gemini',
        version: 1,
        createdBy: 'organizer',
        createdAt: now - 3600000 * 3,
        lastUpdated: now - 3600000 * 3,
        isNew: false,
        isUpdated: false,
        isReviewedByAnchor: false,
        viewedByAnchor: false,
        usageCount: 0,
      ),
    ];
  }
}
