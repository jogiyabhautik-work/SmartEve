import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../models/notification_model.dart';
import '../core/services/neon_database_service.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final NeonDatabaseService _neonService = NeonDatabaseService();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String _filter = 'all';
  String _sort = 'newest';
  String _searchQuery = '';
  bool _unreadOnly = false;
  int _unreadCount = 0;
  String? _statusMessage;
  NotificationPreferences _preferences = const NotificationPreferences(userId: 'user-anchor-1');

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String get filter => _filter;
  String get sort => _sort;
  String get searchQuery => _searchQuery;
  bool get unreadOnly => _unreadOnly;
  int get unreadCount => _unreadCount;
  String? get statusMessage => _statusMessage;
  NotificationPreferences get preferences => _preferences;

  List<NotificationModel> get filtered {
    List<NotificationModel> items = List.of(_notifications.where((n) => !n.isArchived));

    // Category Filter
    if (_filter != 'all') {
      final targetCat = NotificationCategory.fromString(_filter);
      if (targetCat != null) {
        items = items.where((n) {
          final cat = NotificationCategory.fromString(n.category ?? n.type);
          return cat == targetCat;
        }).toList();
      }
    }

    // Unread Only Filter
    if (_unreadOnly) {
      items = items.where((n) => !n.read).toList();
    }

    // Search Filter
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      items = items.where((n) {
        final title = (n.title ?? '').toLowerCase();
        final msg = n.message.toLowerCase();
        final sender = (n.senderName ?? '').toLowerCase();
        final event = (n.eventName ?? '').toLowerCase();
        return title.contains(q) || msg.contains(q) || sender.contains(q) || event.contains(q);
      }).toList();
    }

    // Sorting
    switch (_sort) {
      case 'oldest':
        items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'unread':
        items.sort((a, b) {
          final ra = a.read ? 0 : 1;
          final rb = b.read ? 0 : 1;
          if (ra != rb) return rb.compareTo(ra);
          return b.createdAt.compareTo(a.createdAt);
        });
        break;
      case 'newest':
      default:
        items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return items;
  }

  Future<void> load({String? userId}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _apiClient.get('/anchor/notifications?filter=$_filter&sort=$_sort');
      if (res.success && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        _notifications = (data['notifications'] as List?)
            ?.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
            .toList() ?? [];
        _unreadCount = (data['unreadCount'] as num?)?.toInt() ?? _notifications.where((n) => !n.read).length;
      }

      if (userId != null && userId.isNotEmpty) {
        await loadPreferences(userId);
      }
    } catch (e) {
      _statusMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setFilter(String f) async {
    _filter = f;
    notifyListeners();
  }

  Future<void> setSort(String s) async {
    _sort = s;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void toggleUnreadOnly() {
    _unreadOnly = !_unreadOnly;
    notifyListeners();
  }

  Future<void> markRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    _notifications[idx] = _notifications[idx].copyWith(read: true);
    _unreadCount = _notifications.where((n) => !n.read).length;
    notifyListeners();
    try {
      await _apiClient.post('/anchor/notifications/$id/read', {});
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    _notifications = _notifications.map((n) => n.copyWith(read: true)).toList();
    _unreadCount = 0;
    notifyListeners();
    try {
      await _apiClient.post('/anchor/notifications/mark-all-read', {});
    } catch (_) {}
  }

  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    _unreadCount = _notifications.where((n) => !n.read).length;
    notifyListeners();
    try {
      await _apiClient.delete('/notifications/$id');
    } catch (_) {}
  }

  Future<void> archiveNotification(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    _notifications[idx] = _notifications[idx].copyWith(isArchived: true);
    _unreadCount = _notifications.where((n) => !n.read && !n.isArchived).length;
    notifyListeners();
  }

  Future<void> loadPreferences(String userId) async {
    try {
      final res = await _apiClient.get('/notifications/preferences/$userId');
      if (res.success && res.data != null) {
        _preferences = NotificationPreferences.fromJson(res.data as Map<String, dynamic>);
        notifyListeners();
        return;
      }
      final neonMap = await _neonService.getNotificationPreferences(userId);
      if (neonMap != null) {
        _preferences = NotificationPreferences.fromJson(neonMap);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Load preferences error: $e");
    }
  }

  Future<void> updatePreferences(NotificationPreferences newPrefs) async {
    _preferences = newPrefs;
    notifyListeners();
    try {
      await _apiClient.put('/notifications/preferences/${newPrefs.userId}', newPrefs.toJson());
      await _neonService.saveNotificationPreferences(newPrefs.userId, newPrefs.toJson());
    } catch (e) {
      debugPrint("Update preferences error: $e");
    }
  }

  NotificationModel? _threadNotification;
  List<MessageBubble> _threadMessages = [];
  bool _isThreadLoading = false;

  NotificationModel? get threadNotification => _threadNotification;
  List<MessageBubble> get threadMessages => _threadMessages;
  bool get isThreadLoading => _isThreadLoading;

  Future<void> openThread(String id) async {
    _isThreadLoading = true;
    _threadNotification = null;
    _threadMessages = [];
    notifyListeners();
    try {
      final res = await _apiClient.get('/anchor/notifications/$id');
      if (res.success && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        _threadNotification = NotificationModel.fromJson(data);
        final thread = data['thread'] as List<dynamic>?;
        _threadMessages = thread?.map((e) => MessageBubble.fromJson(e as Map<String, dynamic>)).toList() ?? [];
      }
    } catch (e) {
      _statusMessage = e.toString();
    } finally {
      _isThreadLoading = false;
      notifyListeners();
    }
  }

  void closeThread() {
    _threadNotification = null;
    _threadMessages = [];
    notifyListeners();
  }

  Future<void> reply(String notificationId, String text) async {
    try {
      final res = await _apiClient.post('/anchor/notifications/$notificationId/reply', {'replyText': text});
      if (res.success && res.data != null) {
        final data = res.data as Map<String, dynamic>;
        final msg = MessageBubble.fromJson(data['message'] as Map<String, dynamic>);
        _threadMessages = [..._threadMessages, msg];
        notifyListeners();
        await load();
      }
    } catch (e) {
      _statusMessage = e.toString();
      notifyListeners();
    }
  }
}
