import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../models/checklist_item_model.dart';

class ChecklistProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<ChecklistItemModel> _items = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _eventId;
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  /// Guards async completions that land after dispose.
  void _safeNotifyListeners() {
    if (_isDisposed) return;
    notifyListeners();
  }

  List<ChecklistItemModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get completedCount => _items.where((i) => i.isCompleted).length;
  int get totalCount => _items.length;
  double get completionFraction =>
      totalCount == 0 ? 0.0 : completedCount / totalCount;
  int get completionPercent => (completionFraction * 100).round();
  bool get isAllComplete => totalCount > 0 && completedCount == totalCount;

  /// The 8 canonical pre-event checklist items, seeded locally and replaced
  /// by server state when the backend is reachable.
  void loadForEvent(String eventId) {
    if (_eventId == eventId && _items.isNotEmpty) return;
    _eventId = eventId;
    _seedDefaults();
    _fetchFromBackend();
  }

  void _seedDefaults() {
    final now = DateTime.now().millisecondsSinceEpoch;
    _items = [
      ChecklistItemModel(
        id: 'chk-1',
        itemKey: 'review_speakers',
        label: 'Review all speakers & their details',
        icon: checklistIconFor('review_speakers'),
        orderIndex: 1,
      ),
      ChecklistItemModel(
        id: 'chk-2',
        itemKey: 'memorize_opening',
        label: 'Memorize opening script',
        icon: checklistIconFor('memorize_opening'),
        orderIndex: 2,
      ),
      ChecklistItemModel(
        id: 'chk-3',
        itemKey: 'check_audio',
        label: 'Check audio setup (mic working)',
        icon: checklistIconFor('check_audio'),
        orderIndex: 3,
      ),
      ChecklistItemModel(
        id: 'chk-4',
        itemKey: 'check_video',
        label: 'Check video setup (camera working)',
        icon: checklistIconFor('check_video'),
        orderIndex: 4,
      ),
      ChecklistItemModel(
        id: 'chk-5',
        itemKey: 'review_scripts',
        label: 'Review all generated scripts',
        icon: checklistIconFor('review_scripts'),
        orderIndex: 5,
      ),
      ChecklistItemModel(
        id: 'chk-6',
        itemKey: 'agenda_flow',
        label: 'Familiarize with agenda flow',
        icon: checklistIconFor('agenda_flow'),
        orderIndex: 6,
      ),
      ChecklistItemModel(
        id: 'chk-7',
        itemKey: 'check_internet',
        label: 'Check internet connection',
        icon: checklistIconFor('check_internet'),
        orderIndex: 7,
      ),
      ChecklistItemModel(
        id: 'chk-8',
        itemKey: 'notify_organizer',
        label: 'Notify organizer when ready',
        icon: checklistIconFor('notify_organizer'),
        orderIndex: 8,
      ),
    ];
    // keep `now` referenced to avoid lint when demo timestamps are needed
    assert(now > 0);
    notifyListeners();
  }

  Future<void> _fetchFromBackend() async {
    if (_eventId == null) return;
    _isLoading = true;
    _safeNotifyListeners();
    try {
      final res = await _apiClient.get('/events/$_eventId/checklist');
      if (res.success && res.data is List) {
        final list = (res.data as List)
            .map((e) => ChecklistItemModel.fromJson(e as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) {
          // Merge server completion state onto canonical items by key.
          for (final serverItem in list) {
            final idx = _items.indexWhere((i) => i.itemKey == serverItem.itemKey);
            if (idx != -1) {
              _items[idx].isCompleted = serverItem.isCompleted;
              _items[idx].completedAt = serverItem.completedAt;
            }
          }
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  Future<void> toggleItem(String itemId, bool value) async {
    final idx = _items.indexWhere((i) => i.id == itemId);
    if (idx == -1) return;
    _items[idx].isCompleted = value;
    _items[idx].completedAt =
        value ? DateTime.now().millisecondsSinceEpoch : null;
    notifyListeners();

    if (_eventId != null) {
      // Offline-first: fire-and-forget sync; local state is the source of
      // truth until the next backend load resyncs.
      _apiClient.put('/events/$_eventId/checklist/$itemId', {
        'isCompleted': value,
      }).catchError((_) => ApiResponse<dynamic>(success: false));
    }
  }

  Future<void> markAllComplete() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final item in _items) {
      item.isCompleted = true;
      item.completedAt = now;
    }
    notifyListeners();

    if (_eventId != null) {
      _apiClient
          .post('/events/$_eventId/checklist/complete-all', {})
          .catchError((_) => ApiResponse<dynamic>(success: false));
    }
  }
}
