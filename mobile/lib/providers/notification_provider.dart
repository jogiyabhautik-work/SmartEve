import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String _filter = 'all';
  String _sort = 'newest';
  int _unreadCount = 0;
  String? _statusMessage;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String get filter => _filter;
  String get sort => _sort;
  int get unreadCount => _unreadCount;
  String? get statusMessage => _statusMessage;

  List<NotificationModel> get filtered {
    List<NotificationModel> items;
    if (_filter == 'all') {
      items = List.of(_notifications);
    } else {
      final cat = NotificationCategory.fromString(_filter);
      if (cat == null) {
        items = List.of(_notifications);
      } else {
        items = _notifications.where((n) {
          final ncat = NotificationCategory.fromString(n.category ?? '');
          return ncat == cat;
        }).toList();
      }
    }
    // Client-side sort guarantees correct order even with cached data.
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

  Future<void> load() async {
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
    } catch (e) {
      _statusMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setFilter(String f) async {
    _filter = f;
    await load();
  }

  Future<void> setSort(String s) async {
    _sort = s;
    await load();
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
