import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/firebase_service.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';
import 'widgets/filter_bar.dart';
import 'widgets/notification_card.dart';
import 'widgets/notification_thread_sheet.dart';
import 'widgets/empty_state.dart';

/// Clean notification center with message threading.
///
/// Mobile: full-screen list, tap to expand thread (bottom sheet).
/// Tablet/Desktop: split view (list | thread).
class NotificationCenterScreen extends StatefulWidget {
  final bool isEmbedded;

  const NotificationCenterScreen({super.key, this.isEmbedded = false});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  NotificationCategory _selectedCategory = NotificationCategory.all;
  String _selectedSort = 'newest';
  String? _selectedId; // for tablet/desktop split view
  StreamSubscription? _fcmSub;

  static const _sortOptions = <String, String>{
    'newest': 'Newest First',
    'oldest': 'Oldest First',
    'unread': 'Unread First',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().load();
    });
    // Real-time push: refresh list + show banner when app is open.
    _fcmSub = FirebaseService().onNotificationReceived.listen((msg) {
      if (!mounted) return;
      context.read<NotificationProvider>().load();
      final title = msg.notification?.title ?? 'New notification';
      final body = msg.notification?.body ?? '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title${body.isNotEmpty ? ' — $body' : ''}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  @override
  void dispose() {
    _fcmSub?.cancel();
    super.dispose();
  }

  String _filterValue(NotificationCategory cat) {
    return switch (cat) {
      NotificationCategory.all => 'all',
      NotificationCategory.smartEveAi => 'smart_eve_ai',
      _ => cat.name,
    };
  }

  Future<void> _onSelectCategory(NotificationCategory cat) async {
    setState(() => _selectedCategory = cat);
    await context.read<NotificationProvider>().setFilter(_filterValue(cat));
  }

  Future<void> _onSelectSort(String value) async {
    setState(() => _selectedSort = value);
    await context.read<NotificationProvider>().setSort(value);
  }

  Future<void> _openThread(
      BuildContext context, NotificationModel n) async {
    final provider = context.read<NotificationProvider>();
    await provider.markRead(n.id);
    await provider.openThread(n.id);
    if (!context.mounted) return;
    final isWide = MediaQuery.of(context).size.width >= 600;
    if (isWide) {
      setState(() => _selectedId = n.id);
      return;
    }
    final threadNotif = provider.threadNotification;
    if (threadNotif == null) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => ClipRRect(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
          child: Consumer<NotificationProvider>(
            builder: (context, p, __) {
              final notif = p.threadNotification ?? threadNotif;
              return NotificationThreadSheet(
                notification: notif,
                thread: p.threadMessages,
                replyHint: 'Reply to ${notif.senderName ?? 'sender'}...',
                onReply: (text) => p.reply(notif.id, text),
                onDismiss: () => Navigator.pop(ctx),
              );
            },
          ),
        ),
      ),
    );
    provider.closeThread();
  }

  void _handleQuickAction(BuildContext context, NotificationModel n,
      QuickAction qa) {
    final provider = context.read<NotificationProvider>();
    switch (qa.action) {
      case 'accept':
        provider.markRead(n.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Accepted invitation to ${n.eventName ?? 'event'}'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      case 'decline':
        provider.markRead(n.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Declined invitation to ${n.eventName ?? 'event'}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      case 'view_script':
        provider.markRead(n.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening updated script...'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      case 'view_agenda':
        provider.markRead(n.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening new agenda...'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      case 'acknowledge':
      case 'dismiss':
        provider.markRead(n.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Acknowledged'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      case 'snooze':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('We will remind you later'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      case 'view_suggestions':
        provider.markRead(n.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening SmartEve AI suggestions...'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      default:
        _openThread(context, n);
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        if (isWide) return _buildSplitView(context);
        return _buildList(context, embeddedScroll: widget.isEmbedded);
      },
    );

    if (widget.isEmbedded) return body;

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, p, __) => p.unreadCount > 0
                ? TextButton(
                    onPressed: () => p.markAllRead(),
                    child: const Text('Mark all read'),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          const Text(
            'NOTIFICATIONS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Consumer<NotificationProvider>(
            builder: (context, p, __) => p.unreadCount > 0
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${p.unreadCount} unread',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const Spacer(),
          // Sort Options
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSort,
              icon: const Icon(Icons.sort_rounded,
                  size: 16, color: AppTheme.textSecondary),
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary),
              items: _sortOptions.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) _onSelectSort(v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, {bool embeddedScroll = false}) {
    return Consumer<NotificationProvider>(
      builder: (context, p, __) {
        final items = p.filtered;
        final list = RefreshIndicator(
          onRefresh: () => p.load(),
          child: items.isEmpty && !p.isLoading
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 60),
                    NotificationEmptyState(),
                  ],
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
                  itemCount: items.length + (p.isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= items.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    }
                    final n = items[index];
                    final isAlertUrgent = n.priority == 'urgent' &&
                        (n.category == 'alert' ||
                            NotificationCategory.fromString(
                                    n.category ?? '') ==
                                NotificationCategory.alert);
                    final card = NotificationCard(
                      notification: n,
                      onTap: () => _openThread(context, n),
                      onQuickAction: () {
                        final qa = n.quickActions?.isNotEmpty == true
                            ? n.quickActions!.first
                            : null;
                        if (qa != null) {
                          _handleQuickAction(context, n, qa);
                        }
                      },
                    );
                    if (!isAlertUrgent) return card;
                    // Urgent alerts: red background per plan
                    return Container(
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                AppTheme.error.withValues(alpha: 0.35)),
                      ),
                      margin: const EdgeInsets.only(bottom: 2),
                      child: card,
                    );
                  },
                ),
        );

        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 6),
            NotificationFilterBar(
              selected: _selectedCategory,
              onSelected: _onSelectCategory,
            ),
            const SizedBox(height: 8),
            Expanded(child: list),
          ],
        );

        if (embeddedScroll) return content;
        return content;
      },
    );
  }

  Widget _buildSplitView(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, p, __) {
        final items = p.filtered;
        final selected = items
            .where((e) => e.id == _selectedId)
            .cast<NotificationModel?>()
            .firstWhere((e) => e != null, orElse: () => null);
        final threadNotif = p.threadNotification ?? selected;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 6),
            NotificationFilterBar(
              selected: _selectedCategory,
              onSelected: _onSelectCategory,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // List pane
                  Expanded(
                    flex: 5,
                    child: RefreshIndicator(
                      onRefresh: () => p.load(),
                      child: items.isEmpty && !p.isLoading
                          ? ListView(
                              physics:
                                  const AlwaysScrollableScrollPhysics(),
                              children: const [
                                SizedBox(height: 60),
                                NotificationEmptyState(),
                              ],
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(12, 4, 6, 40),
                              itemCount: items.length,
                              itemBuilder: (context, index) {
                                final n = items[index];
                                return Container(
                                  decoration: _selectedId == n.id
                                      ? BoxDecoration(
                                          border: Border.all(
                                              color: AppTheme.primaryBlue,
                                              width: 1.5),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        )
                                      : null,
                                  child: NotificationCard(
                                    notification: n,
                                    onTap: () async {
                                      setState(
                                          () => _selectedId = n.id);
                                      await p.markRead(n.id);
                                      await p.openThread(n.id);
                                    },
                                    onQuickAction: () {
                                      final qa = n.quickActions
                                                  ?.isNotEmpty ==
                                              true
                                          ? n.quickActions!.first
                                          : null;
                                      if (qa != null) {
                                        _handleQuickAction(
                                            context, n, qa);
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  // Thread pane
                  Expanded(
                    flex: 6,
                    child: threadNotif == null
                        ? const Center(
                            child: Text(
                              'Select a notification to view the thread',
                              style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 13),
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(12),
                            child: NotificationThreadSheet(
                              notification: threadNotif,
                              thread: p.threadMessages,
                              replyHint:
                                  'Reply to ${threadNotif.senderName ?? 'sender'}...',
                              onReply: (text) =>
                                  p.reply(threadNotif.id, text),
                              onDismiss: () {
                                p.closeThread();
                                setState(() => _selectedId = null);
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
