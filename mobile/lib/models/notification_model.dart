import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

enum NotificationCategory {
  all('All'),
  invitation('Invitations'),
  update('Updates'),
  announcement('Announcements'),
  message('Messages'),
  alert('Alerts'),
  smartEveAi('AI Ready');

  final String label;
  const NotificationCategory(this.label);

  static NotificationCategory? fromString(String value) {
    final v = value.toLowerCase();
    switch (v) {
      case 'invitation':
        return NotificationCategory.invitation;
      case 'update':
        return NotificationCategory.update;
      case 'announcement':
        return NotificationCategory.announcement;
      case 'message':
        return NotificationCategory.message;
      case 'alert':
        return NotificationCategory.alert;
      case 'smart_eve_ai':
      case 'smarteveai':
      case 'smart eve ai':
      case 'ai ready':
        return NotificationCategory.smartEveAi;
      default:
        return null;
    }
  }

  static Color badgeColorFor(NotificationCategory category) {
    return switch (category) {
      NotificationCategory.invitation => AppTheme.primaryPurple,
      NotificationCategory.update => AppTheme.primaryBlue,
      NotificationCategory.announcement => AppTheme.success,
      NotificationCategory.message => AppTheme.textMuted,
      NotificationCategory.alert => AppTheme.error,
      NotificationCategory.smartEveAi => AppTheme.cyan,
      NotificationCategory.all => AppTheme.primaryBlue,
    };
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
  final String? title;
  final String? detailedText;
  final String? senderName;
  final String? senderAvatarUrl;
  final String? senderRole;
  final String? senderStatus;
  final String? eventId;
  final String? eventName;
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
    this.title,
    this.detailedText,
    this.senderName,
    this.senderAvatarUrl,
    this.senderRole,
    this.senderStatus,
    this.eventId,
    this.eventName,
    this.attachments = const [],
    this.replyCount,
    this.thread,
    this.quickActions,
    this.category,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'announcement',
      message: json['message'] as String? ?? '',
      createdBy: json['createdBy'] as String? ?? 'system',
      createdAt: (json['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      priority: json['priority'] as String? ?? 'normal',
      read: json['read'] as bool? ?? false,
      title: json['title'] as String?,
      detailedText: json['detailedText'] as String?,
      senderName: json['senderName'] as String?,
      senderAvatarUrl: json['senderAvatarUrl'] as String?,
      senderRole: json['senderRole'] as String?,
      senderStatus: json['senderStatus'] as String?,
      eventId: json['eventId'] as String?,
      eventName: json['eventName'] as String?,
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
      category: NotificationCategory.fromString(
              json['category'] as String? ?? '') ?.name ??
          json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'message': message,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'priority': priority,
      'read': read,
      if (title != null) 'title': title,
      if (detailedText != null) 'detailedText': detailedText,
      if (senderName != null) 'senderName': senderName,
      if (senderAvatarUrl != null) 'senderAvatarUrl': senderAvatarUrl,
      if (senderRole != null) 'senderRole': senderRole,
      if (senderStatus != null) 'senderStatus': senderStatus,
      if (eventId != null) 'eventId': eventId,
      if (eventName != null) 'eventName': eventName,
      if (attachments.isNotEmpty) 'attachments': attachments,
      if (replyCount != null) 'replyCount': replyCount,
      if (thread != null) 'thread': thread,
      if (quickActions != null) 'quickActions': quickActions,
      if (category != null) 'category': category,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? type,
    String? message,
    String? createdBy,
    int? createdAt,
    String? priority,
    bool? read,
    String? title,
    String? detailedText,
    String? senderName,
    String? senderAvatarUrl,
    String? senderRole,
    String? senderStatus,
    String? eventId,
    String? eventName,
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
      title: title ?? this.title,
      detailedText: detailedText ?? this.detailedText,
      senderName: senderName ?? this.senderName,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
      senderRole: senderRole ?? this.senderRole,
      senderStatus: senderStatus ?? this.senderStatus,
      eventId: eventId ?? this.eventId,
      eventName: eventName ?? this.eventName,
      attachments: attachments ?? this.attachments,
      replyCount: replyCount ?? this.replyCount,
      thread: thread ?? this.thread,
      quickActions: quickActions ?? this.quickActions,
      category: category ?? this.category,
    );
  }

  bool get isUnread => !read;

  Color badgeColor() {
    final cat = NotificationCategory.fromString(category ?? '');
    if (cat != null) return NotificationCategory.badgeColorFor(cat);
    return switch (type) {
      'invitation' => AppTheme.primaryPurple,
      'delay' || 'cancel' => AppTheme.error,
      'change' || 'script_update' || 'agenda_change' => AppTheme.primaryBlue,
      'announcement' || 'starting' || 'done' => AppTheme.success,
      'message' => AppTheme.textMuted,
      'smart_eve_ai' => AppTheme.cyan,
      _ => AppTheme.primaryBlue,
    };
  }

  String? get categoryLabel {
    final cat = NotificationCategory.fromString(category ?? '');
    return cat?.label;
  }
}
