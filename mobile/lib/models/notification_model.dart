import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

enum NotificationCategory {
  all('All'),
  invitation('Invitations'),
  message('Messages'),
  update('Updates'),
  alert('Alerts'),
  reminder('Reminders'),
  smartEveAi('AI Ready');

  final String label;
  const NotificationCategory(this.label);

  static NotificationCategory? fromString(String value) {
    final v = value.toLowerCase();
    if (v.contains('invitation')) return NotificationCategory.invitation;
    if (v.contains('message')) return NotificationCategory.message;
    if (v.contains('update') || v.contains('script') || v.contains('agenda')) return NotificationCategory.update;
    if (v.contains('alert') || v.contains('delay') || v.contains('sos') || v.contains('emergency')) return NotificationCategory.alert;
    if (v.contains('reminder') || v.contains('live') || v.contains('starting')) return NotificationCategory.reminder;
    if (v.contains('ai') || v.contains('smart_eve')) return NotificationCategory.smartEveAi;
    return NotificationCategory.all;
  }

  static Color badgeColorFor(NotificationCategory category) {
    return switch (category) {
      NotificationCategory.invitation => AppTheme.primaryPurple,
      NotificationCategory.message => AppTheme.primaryBlue,
      NotificationCategory.update => AppTheme.success,
      NotificationCategory.alert => AppTheme.error,
      NotificationCategory.reminder => AppTheme.warning,
      NotificationCategory.smartEveAi => AppTheme.cyan,
      NotificationCategory.all => AppTheme.primaryBlue,
    };
  }

  static IconData iconFor(NotificationCategory category) {
    return switch (category) {
      NotificationCategory.invitation => Icons.mic_rounded,
      NotificationCategory.message => Icons.chat_bubble_rounded,
      NotificationCategory.update => Icons.description_rounded,
      NotificationCategory.alert => Icons.warning_amber_rounded,
      NotificationCategory.reminder => Icons.notifications_active_rounded,
      NotificationCategory.smartEveAi => Icons.auto_awesome_rounded,
      NotificationCategory.all => Icons.notifications_none_rounded,
    };
  }
}

enum NotificationType {
  anchorInvitation('anchor_invitation', 'Anchor Invitation', Icons.mic_rounded, AppTheme.primaryPurple, 'invitation', 'high'),
  invitationAccepted('invitation_accepted', 'Invitation Accepted', Icons.check_circle_rounded, AppTheme.success, 'invitation', 'medium'),
  invitationDeclined('invitation_declined', 'Invitation Declined', Icons.cancel_rounded, AppTheme.error, 'invitation', 'high'),
  scriptsGenerated('scripts_generated', 'Scripts Generated', Icons.description_rounded, AppTheme.success, 'update', 'medium'),
  scriptsUpdated('scripts_updated', 'Script Updated', Icons.edit_document, AppTheme.primaryBlue, 'update', 'medium'),
  scriptApprovalRequired('script_approval_required', 'Approval Required', Icons.verified_rounded, AppTheme.warning, 'update', 'high'),
  scriptModificationRequest('script_modification_request', 'Modification Request', Icons.published_with_changes_rounded, AppTheme.primaryPurple, 'update', 'high'),
  agendaUpdated('agenda_updated', 'Agenda Updated', Icons.schedule_rounded, AppTheme.cyan, 'update', 'medium'),
  speakerAdded('speaker_added', 'Speaker Added', Icons.person_add_rounded, AppTheme.primaryBlue, 'update', 'medium'),
  eventDelay('event_delay', 'Event Delay', Icons.alarm_rounded, AppTheme.error, 'alert', 'high'),
  delayApproved('delay_approved', 'Delay Approved', Icons.check_circle_outline_rounded, AppTheme.success, 'alert', 'high'),
  directMessage('direct_message', 'Direct Message', Icons.chat_rounded, AppTheme.primaryBlue, 'message', 'medium'),
  eventReminder('event_reminder', 'Event Reminder', Icons.notifications_active_rounded, AppTheme.warning, 'reminder', 'high'),
  eventLive('event_live', 'Event Going Live', Icons.sensors_rounded, AppTheme.error, 'alert', 'urgent'),
  anchorReady('anchor_ready', 'Anchor Ready', Icons.how_to_reg_rounded, AppTheme.success, 'update', 'medium'),
  announcement('announcement', 'Announcement', Icons.campaign_rounded, AppTheme.warning, 'update', 'medium'),
  emergencySOS('emergency_sos', 'Emergency SOS', Icons.emergency_rounded, AppTheme.error, 'alert', 'urgent'),
  nextActivity('next_activity', 'Next Activity', Icons.skip_next_rounded, AppTheme.primaryBlue, 'update', 'high'),
  scriptReady('script_ready', 'Script Ready', Icons.menu_book_rounded, AppTheme.primaryBlue, 'update', 'high'),
  eventCompleted('event_completed', 'Event Completed', Icons.celebration_rounded, AppTheme.warningAmber, 'update', 'medium'),
  organizerFeedback('organizer_feedback', 'Performance Feedback', Icons.star_rounded, AppTheme.warningAmber, 'update', 'medium'),
  anchorNotResponding('anchor_not_responding', 'Anchor Not Responding', Icons.person_off_rounded, AppTheme.error, 'alert', 'urgent'),
  engagementAlert('engagement_alert', 'Engagement Alert', Icons.analytics_rounded, AppTheme.cyan, 'alert', 'medium');

  final String code;
  final String label;
  final IconData icon;
  final Color color;
  final String category;
  final String priority;

  const NotificationType(this.code, this.label, this.icon, this.color, this.category, this.priority);

  static NotificationType fromCode(String code) {
    final clean = code.toLowerCase().trim();
    for (final t in NotificationType.values) {
      if (t.code == clean) return t;
    }
    if (clean.contains('invitation')) return NotificationType.anchorInvitation;
    if (clean.contains('message')) return NotificationType.directMessage;
    if (clean.contains('delay')) return NotificationType.eventDelay;
    if (clean.contains('sos') || clean.contains('emergency')) return NotificationType.emergencySOS;
    if (clean.contains('script')) return NotificationType.scriptsUpdated;
    return NotificationType.announcement;
  }
}

class NotificationPreferences {
  final String userId;
  final bool pushEnabled;
  final bool inAppEnabled;
  final bool emailEnabled;
  final bool invitationsEnabled;
  final bool messagesEnabled;
  final bool updatesEnabled;
  final bool announcementsEnabled;
  final bool alertsEnabled;
  final bool remindersEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool quietHoursEnabled;
  final String quietHoursStart;
  final String quietHoursEnd;
  final String quietHoursTimezone;
  final bool dailyDigestEnabled;
  final String digestTime;

  const NotificationPreferences({
    required this.userId,
    this.pushEnabled = true,
    this.inAppEnabled = true,
    this.emailEnabled = true,
    this.invitationsEnabled = true,
    this.messagesEnabled = true,
    this.updatesEnabled = true,
    this.announcementsEnabled = true,
    this.alertsEnabled = true,
    this.remindersEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.quietHoursEnabled = false,
    this.quietHoursStart = '22:00:00',
    this.quietHoursEnd = '07:00:00',
    this.quietHoursTimezone = 'UTC',
    this.dailyDigestEnabled = false,
    this.digestTime = '09:00:00',
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      userId: json['userId'] as String? ?? json['user_id'] as String? ?? '',
      pushEnabled: json['pushEnabled'] as bool? ?? json['push_enabled'] as bool? ?? true,
      inAppEnabled: json['inAppEnabled'] as bool? ?? json['in_app_enabled'] as bool? ?? true,
      emailEnabled: json['emailEnabled'] as bool? ?? json['email_enabled'] as bool? ?? true,
      invitationsEnabled: json['invitationsEnabled'] as bool? ?? json['invitations_enabled'] as bool? ?? true,
      messagesEnabled: json['messagesEnabled'] as bool? ?? json['messages_enabled'] as bool? ?? true,
      updatesEnabled: json['updatesEnabled'] as bool? ?? json['updates_enabled'] as bool? ?? true,
      announcementsEnabled: json['announcementsEnabled'] as bool? ?? json['announcements_enabled'] as bool? ?? true,
      alertsEnabled: json['alertsEnabled'] as bool? ?? json['alerts_enabled'] as bool? ?? true,
      remindersEnabled: json['remindersEnabled'] as bool? ?? json['reminders_enabled'] as bool? ?? true,
      soundEnabled: json['soundEnabled'] as bool? ?? json['sound_enabled'] as bool? ?? true,
      vibrationEnabled: json['vibrationEnabled'] as bool? ?? json['vibration_enabled'] as bool? ?? true,
      quietHoursEnabled: json['quietHoursEnabled'] as bool? ?? json['quiet_hours_enabled'] as bool? ?? false,
      quietHoursStart: json['quietHoursStart'] as String? ?? json['quiet_hours_start'] as String? ?? '22:00:00',
      quietHoursEnd: json['quietHoursEnd'] as String? ?? json['quiet_hours_end'] as String? ?? '07:00:00',
      quietHoursTimezone: json['quietHoursTimezone'] as String? ?? json['quiet_hours_timezone'] as String? ?? 'UTC',
      dailyDigestEnabled: json['dailyDigestEnabled'] as bool? ?? json['daily_digest_enabled'] as bool? ?? false,
      digestTime: json['digestTime'] as String? ?? json['digest_time'] as String? ?? '09:00:00',
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'pushEnabled': pushEnabled,
        'inAppEnabled': inAppEnabled,
        'emailEnabled': emailEnabled,
        'invitationsEnabled': invitationsEnabled,
        'messagesEnabled': messagesEnabled,
        'updatesEnabled': updatesEnabled,
        'announcementsEnabled': announcementsEnabled,
        'alertsEnabled': alertsEnabled,
        'remindersEnabled': remindersEnabled,
        'soundEnabled': soundEnabled,
        'vibrationEnabled': vibrationEnabled,
        'quietHoursEnabled': quietHoursEnabled,
        'quietHoursStart': quietHoursStart,
        'quietHoursEnd': quietHoursEnd,
        'quietHoursTimezone': quietHoursTimezone,
        'dailyDigestEnabled': dailyDigestEnabled,
        'digestTime': digestTime,
      };

  NotificationPreferences copyWith({
    bool? pushEnabled,
    bool? inAppEnabled,
    bool? emailEnabled,
    bool? invitationsEnabled,
    bool? messagesEnabled,
    bool? updatesEnabled,
    bool? announcementsEnabled,
    bool? alertsEnabled,
    bool? remindersEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    String? quietHoursTimezone,
    bool? dailyDigestEnabled,
    String? digestTime,
  }) {
    return NotificationPreferences(
      userId: userId,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      inAppEnabled: inAppEnabled ?? this.inAppEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      invitationsEnabled: invitationsEnabled ?? this.invitationsEnabled,
      messagesEnabled: messagesEnabled ?? this.messagesEnabled,
      updatesEnabled: updatesEnabled ?? this.updatesEnabled,
      announcementsEnabled: announcementsEnabled ?? this.announcementsEnabled,
      alertsEnabled: alertsEnabled ?? this.alertsEnabled,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      quietHoursTimezone: quietHoursTimezone ?? this.quietHoursTimezone,
      dailyDigestEnabled: dailyDigestEnabled ?? this.dailyDigestEnabled,
      digestTime: digestTime ?? this.digestTime,
    );
  }
}

class Attachment {
  final String id;
  final String type;
  final String url;
  final String name;
  final int sizeBytes;
  final int createdAt;

  const Attachment({
    required this.id,
    required this.type,
    required this.url,
    required this.name,
    this.sizeBytes = 0,
    this.createdAt = 0,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) => Attachment(
        id: json['id'] as String? ?? '',
        type: json['type'] as String? ?? 'image',
        url: json['url'] as String? ?? '',
        name: json['name'] as String? ?? '',
        sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
        createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
      );
}

class MessageBubble {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final int createdAt;
  final List<Attachment> attachments;
  final bool isOwn;

  const MessageBubble({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.createdAt,
    this.attachments = const [],
    this.isOwn = false,
  });

  factory MessageBubble.fromJson(Map<String, dynamic> json) => MessageBubble(
        id: json['id'] as String? ?? '',
        senderId: json['senderId'] as String? ?? '',
        senderName: json['senderName'] as String? ?? '',
        text: json['text'] as String? ?? '',
        createdAt: (json['createdAt'] as num?)?.toInt() ?? 0,
        attachments: (json['attachments'] as List<dynamic>?)
            ?.map((e) => Attachment.fromJson(e as Map<String, dynamic>))
            .toList() ?? const [],
        isOwn: json['isOwn'] as bool? ?? false,
      );
}

class QuickAction {
  final String label;
  final String action;
  final String? icon;

  const QuickAction({
    required this.label,
    required this.action,
    this.icon,
  });

  factory QuickAction.fromJson(Map<String, dynamic> json) => QuickAction(
        label: json['label'] as String? ?? '',
        action: json['action'] as String? ?? '',
        icon: json['icon'] as String?,
      );
}

class NotificationModel {
  final String id;
  final String type;
  final String message;
  final String createdBy;
  final int createdAt;
  final String priority;
  final bool read;
  final bool isArchived;
  final String? title;
  final String? detailedText;
  final String? senderName;
  final String? senderAvatarUrl;
  final String? senderRole;
  final String? senderStatus;
  final String? eventId;
  final String? eventName;
  final String? actionUrl;
  final List<Attachment> attachments;
  final int? replyCount;
  final List<MessageBubble>? thread;
  final List<QuickAction>? quickActions;
  final String? category;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.message,
    required this.createdBy,
    required this.createdAt,
    this.priority = 'normal',
    this.read = false,
    this.isArchived = false,
    this.title,
    this.detailedText,
    this.senderName,
    this.senderAvatarUrl,
    this.senderRole,
    this.senderStatus,
    this.eventId,
    this.eventName,
    this.actionUrl,
    this.attachments = const [],
    this.replyCount,
    this.thread,
    this.quickActions,
    this.category,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? json['notification_type'] as String? ?? 'announcement';
    return NotificationModel(
      id: json['id'] as String? ?? '',
      type: typeStr,
      message: json['message'] as String? ?? '',
      createdBy: json['createdBy'] as String? ?? json['sender_id'] as String? ?? 'system',
      createdAt: json['createdAt'] is int
          ? json['createdAt'] as int
          : json['created_at'] is String
              ? DateTime.tryParse(json['created_at'])?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch
              : (json['created_at'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      priority: json['priority'] as String? ?? 'normal',
      read: json['read'] as bool? ?? json['is_read'] as bool? ?? false,
      isArchived: json['isArchived'] as bool? ?? false,
      title: json['title'] as String?,
      detailedText: json['detailedText'] as String?,
      senderName: json['senderName'] as String?,
      senderAvatarUrl: json['senderAvatarUrl'] as String?,
      senderRole: json['senderRole'] as String? ?? json['recipient_role'] as String?,
      senderStatus: json['senderStatus'] as String?,
      eventId: json['eventId'] as String? ?? json['event_id'] as String?,
      eventName: json['eventName'] as String?,
      actionUrl: json['actionUrl'] as String? ?? json['action_url'] as String?,
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => Attachment.fromJson(e as Map<String, dynamic>))
          .toList() ?? const [],
      replyCount: (json['replyCount'] as num?)?.toInt(),
      thread: (json['thread'] as List<dynamic>?)
          ?.map((e) => MessageBubble.fromJson(e as Map<String, dynamic>))
          .toList(),
      quickActions: (json['quickActions'] as List<dynamic>?)
          ?.map((e) => QuickAction.fromJson(e as Map<String, dynamic>))
          .toList(),
      category: json['category'] as String? ?? NotificationCategory.fromString(typeStr)?.name,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'message': message,
        'createdBy': createdBy,
        'createdAt': createdAt,
        'priority': priority,
        'read': read,
        'isArchived': isArchived,
        if (title != null) 'title': title,
        if (detailedText != null) 'detailedText': detailedText,
        if (senderName != null) 'senderName': senderName,
        if (senderAvatarUrl != null) 'senderAvatarUrl': senderAvatarUrl,
        if (senderRole != null) 'senderRole': senderRole,
        if (senderStatus != null) 'senderStatus': senderStatus,
        if (eventId != null) 'eventId': eventId,
        if (eventName != null) 'eventName': eventName,
        if (actionUrl != null) 'actionUrl': actionUrl,
        if (attachments.isNotEmpty) 'attachments': attachments,
        if (replyCount != null) 'replyCount': replyCount,
        if (thread != null) 'thread': thread,
        if (quickActions != null) 'quickActions': quickActions,
        if (category != null) 'category': category,
      };

  NotificationModel copyWith({
    String? id,
    String? type,
    String? message,
    String? createdBy,
    int? createdAt,
    String? priority,
    bool? read,
    bool? isArchived,
    String? title,
    String? detailedText,
    String? senderName,
    String? senderAvatarUrl,
    String? senderRole,
    String? senderStatus,
    String? eventId,
    String? eventName,
    String? actionUrl,
    List<Attachment>? attachments,
    int? replyCount,
    List<MessageBubble>? thread,
    List<QuickAction>? quickActions,
    String? category,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      type: type ?? this.type,
      message: message ?? this.message,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      priority: priority ?? this.priority,
      read: read ?? this.read,
      isArchived: isArchived ?? this.isArchived,
      title: title ?? this.title,
      detailedText: detailedText ?? this.detailedText,
      senderName: senderName ?? this.senderName,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
      senderRole: senderRole ?? this.senderRole,
      senderStatus: senderStatus ?? this.senderStatus,
      eventId: eventId ?? this.eventId,
      eventName: eventName ?? this.eventName,
      actionUrl: actionUrl ?? this.actionUrl,
      attachments: attachments ?? this.attachments,
      replyCount: replyCount ?? this.replyCount,
      thread: thread ?? this.thread,
      quickActions: quickActions ?? this.quickActions,
      category: category ?? this.category,
    );
  }

  bool get isUnread => !read;

  NotificationType get typedType => NotificationType.fromCode(type);

  Color badgeColor() {
    return typedType.color;
  }

  IconData iconData() {
    return typedType.icon;
  }

  String? get categoryLabel {
    final cat = NotificationCategory.fromString(category ?? type);
    return cat?.label;
  }
}
