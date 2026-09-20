import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/notification_model.dart';

class NotificationThreadSheet extends StatefulWidget {
  final NotificationModel notification;
  final List<MessageBubble> thread;
  final String replyHint;
  final Future<void> Function(String text) onReply;
  final VoidCallback onDismiss;

  const NotificationThreadSheet({
    super.key,
    required this.notification,
    required this.thread,
    required this.replyHint,
    required this.onReply,
    required this.onDismiss,
  });

  @override
  State<NotificationThreadSheet> createState() =>
      _NotificationThreadSheetState();
}

class _NotificationThreadSheetState extends State<NotificationThreadSheet> {
  late final TextEditingController _replyController;
  bool _sending = false;

  NotificationModel get notification => widget.notification;
  List<MessageBubble> get thread => widget.thread;

  Color get _accent => notification.badgeColor();

  @override
  void initState() {
    super.initState();
    _replyController = TextEditingController();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.onReply(text);
      _replyController.clear();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  IconData _categoryIcon() {
    final cat = NotificationCategory.fromString(notification.category ?? '');
    return switch (cat) {
      NotificationCategory.invitation => Icons.card_membership_rounded,
      NotificationCategory.update => Icons.refresh_rounded,
      NotificationCategory.announcement => Icons.campaign_rounded,
      NotificationCategory.message => Icons.chat_bubble_outline_rounded,
      NotificationCategory.alert => Icons.warning_amber_rounded,
      NotificationCategory.smartEveAi => Icons.auto_awesome_rounded,
      _ => Icons.info_outline_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Header: close + title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 22, color: AppTheme.textSecondary),
                    onPressed: widget.onDismiss,
                    padding: const EdgeInsets.all(0),
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      notification.senderName != null &&
                              notification.eventName != null
                          ? 'Message with ${notification.senderName}'
                          : notification.title ?? 'Notification',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  if (notification.replyCount != null &&
                      notification.replyCount! > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${notification.replyCount} replies',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.border),

            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    // Sender info card
                    _senderInfoCard(),
                    const SizedBox(height: 14),

                    // Main notification content (expanded)
                    _mainContent(),
                    const SizedBox(height: 16),

                    // Thread section (chronological, oldest at top)
                    if (thread.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'THREAD',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _threadList(),
                      if (notification.attachments.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 14),
                          child: _attachmentGrid(
                              context, notification.attachments),
                        ),
                      ],
                    ],
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // Reply input bar (fixed at bottom)
            _replyBar(context),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _senderInfoCard() {
    final n = notification;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: _accent.withValues(alpha: 0.12),
            backgroundImage:
                n.senderAvatarUrl != null && n.senderAvatarUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(n.senderAvatarUrl!)
                    : null,
            child: n.senderAvatarUrl == null || n.senderAvatarUrl!.isEmpty
                ? Icon(_categoryIcon(), size: 14, color: _accent)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        n.senderName ?? 'Sender',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: _onlineColor().withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Icon(
                        _onlineIcon(),
                        size: 8,
                        color: _onlineColor(),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _onlineLabel(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    const Icon(Icons.circle_outlined,
                        size: 9, color: AppTheme.textMuted),
                    const SizedBox(width: 3),
                    Text(
                      n.senderRole ?? 'Sender',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (n.eventName != null &&
                        n.eventName!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.folder_outlined,
                          size: 9, color: AppTheme.textMuted),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          n.eventName!,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mainContent() {
    final n = notification;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: _accent.withValues(alpha: 0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_categoryIcon(), size: 14, color: _accent),
              const SizedBox(width: 5),
              Text(
                n.categoryLabel ?? 'Notification',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: _accent,
                  letterSpacing: 0.4,
                ),
              ),
              const Spacer(),
              const Icon(Icons.event_note_rounded,
                  size: 12, color: AppTheme.textMuted),
              const SizedBox(width: 3),
              Text(
                _timeAgo(n.createdAt),
                style: const TextStyle(
                    fontSize: 10.5, color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            n.detailedText ?? n.message,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppTheme.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _threadList() {
    if (thread.isEmpty) return const SizedBox.shrink();
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      itemCount: thread.length,
      itemBuilder: (context, index) {
        final msg = thread[index];
        final showSenderName = !msg.isOwn &&
            (index == 0 ||
                thread[index - 1].senderId != msg.senderId);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: msg.isOwn
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (showSenderName)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    msg.senderName,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
              Row(
                mainAxisAlignment: msg.isOwn
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: msg.isOwn
                            ? AppTheme.primaryBlue
                            : AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            msg.text,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: msg.isOwn
                                  ? Colors.white
                                  : AppTheme.textPrimary,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _timeAgo(msg.createdAt),
                            style: TextStyle(
                              fontSize: 9,
                              color: msg.isOwn
                                  ? Colors.white70
                                  : AppTheme.textMuted,
                            ),
                          ),
                          if (msg.attachments.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            _attachmentGrid(
                                context, msg.attachments),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _attachmentGrid(
      BuildContext context, List<Attachment> attachments) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: attachments.map((a) {
        if (a.type == 'image') {
          return InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Preview: ${a.name}'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                a.url,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 60,
                  height: 60,
                  color: AppTheme.surfaceLight,
                  child: const Icon(Icons.broken_image,
                      color: AppTheme.textMuted),
                ),
              ),
            ),
          );
        }
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Document: ${a.name}'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.description_outlined,
                    color: AppTheme.textSecondary, size: 18),
                const SizedBox(height: 2),
                Text(
                  a.name.isNotEmpty ? a.name : 'Document',
                  style: const TextStyle(
                      fontSize: 8, color: AppTheme.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _replyBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _replyController,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: widget.replyHint,
                hintStyle: const TextStyle(
                    color: AppTheme.textMuted, fontSize: 12.5),
                filled: true,
                fillColor: AppTheme.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide:
                      const BorderSide(color: AppTheme.border),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.attach_file_rounded,
                size: 20, color: AppTheme.textMuted),
            tooltip: 'Attach file',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Attach file (demo)'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded,
                    size: 20, color: AppTheme.primaryBlue),
            tooltip: 'Send',
            onPressed: _send,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  String _timeAgo(int createdAt) {
    final diff = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(createdAt));
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Color _onlineColor() {
    return switch (notification.senderStatus) {
      'online' => AppTheme.success,
      'away' => AppTheme.warning,
      _ => AppTheme.textMuted,
    };
  }

  IconData _onlineIcon() {
    return switch (notification.senderStatus) {
      'online' => Icons.circle_rounded,
      'away' => Icons.circle_rounded,
      _ => Icons.circle_outlined,
    };
  }

  String _onlineLabel() {
    return switch (notification.senderStatus) {
      'online' => 'Online',
      'away' => 'Away',
      'offline' => 'Offline',
      _ => 'Offline',
    };
  }
}
