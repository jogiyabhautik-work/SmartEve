import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/notification_model.dart';

class NotificationCard extends StatefulWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback? onQuickAction;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
    this.onQuickAction,
  });

  @override
  State<NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<NotificationCard> {
  bool _expanded = false;

  Color get _badgeColor => widget.notification.badgeColor();
  bool get _isUnread => widget.notification.isUnread;

  String _timeAgo() {
    final diff = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(widget.notification.createdAt));
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min${diff.inMinutes == 1 ? '' : 's'} ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    final weeks = (diff.inDays / 7).floor();
    if (weeks < 5) return '${weeks}w ago';
    final months = (diff.inDays / 30).floor();
    return '${months}mo ago';
  }

  IconData _categoryIcon() {
    final cat = NotificationCategory.fromString(widget.notification.category ?? '');
    return switch (cat) {
      NotificationCategory.invitation => Icons.card_membership_rounded,
      NotificationCategory.update => Icons.refresh_rounded,
      NotificationCategory.message => Icons.chat_bubble_outline_rounded,
      NotificationCategory.alert => Icons.campaign_rounded,
      NotificationCategory.smartEveAi => Icons.auto_awesome_rounded,
      _ => Icons.info_outline_rounded,
    };
  }

  String _categoryLabel() {
    return widget.notification.categoryLabel ?? 'Notification';
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(
              color: _isUnread ? AppTheme.primaryBlue.withValues(alpha: 0.3) : AppTheme.border,
            ),
            boxShadow: _isUnread
                ? [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sender row + time
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  _avatar(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sender name + time + event tag
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                n.senderName ?? 'System',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _timeAgo(),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        if (n.eventName != null && n.eventName!.isNotEmpty) ...
                          [
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              margin: const EdgeInsets.only(left: 1),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                n.eventName!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Category badge + unread indicator
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: _badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _badgeColor.withValues(alpha: 0.5), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_categoryIcon(), size: 10, color: _badgeColor),
                            const SizedBox(width: 3),
                            Text(
                              _categoryLabel(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _badgeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_isUnread)
                        Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(right: 2),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Message preview (expandable)
              AnimatedCrossFade(
                firstChild: Text(
                  n.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
                secondChild: Text(
                  n.detailedText ?? n.message,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
                crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),

              const SizedBox(height: 6),

              // Quick actions (only when collapsed); on tap -> mark read + notify parent
              if (n.quickActions != null && n.quickActions!.isNotEmpty && !_expanded)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: n.quickActions!.map((qa) {
                    return InkWell(
                      onTap: () {
                        setState(() => _expanded = false);
                        widget.onQuickAction?.call();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          qa.label,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 6),

              // Tap hint (toggles inline expand without opening thread)
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                borderRadius: BorderRadius.circular(6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _expanded ? 'Show less' : 'Tap to open thread',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: AppTheme.textMuted,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatar() {
    final n = widget.notification;
    if (n.senderAvatarUrl != null && n.senderAvatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
        backgroundImage: CachedNetworkImageProvider(n.senderAvatarUrl!),
        child: n.senderName != null
            ? Text(
                n.senderName!.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              )
            : null,
      );
    }
    // Fallback avatar by role / system
    final icon = switch (n.senderRole) {
      'organizer' => Icons.people_alt_outlined,
      'admin' => Icons.admin_panel_settings_outlined,
      'system' || 'ai' => Icons.auto_awesome_rounded,
      _ => Icons.person_outline_rounded,
    };
    return CircleAvatar(
      radius: 20,
      backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
      child: Icon(icon, size: 18, color: AppTheme.primaryBlue),
    );
  }
}
