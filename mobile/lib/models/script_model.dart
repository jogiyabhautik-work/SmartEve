import 'package:flutter/material.dart';

class ScriptModificationRequest {
  final String id;
  final String scriptId;
  final String anchorName;
  final String feedbackNote;
  final String priority; // 'low' | 'medium' | 'urgent'
  final int timestamp;
  final String status; // 'pending' | 'resolved'

  const ScriptModificationRequest({
    required this.id,
    required this.scriptId,
    required this.anchorName,
    required this.feedbackNote,
    this.priority = 'medium',
    required this.timestamp,
    this.status = 'pending',
  });

  factory ScriptModificationRequest.fromJson(Map<String, dynamic> json) {
    return ScriptModificationRequest(
      id: json['id'] as String? ?? 'req-${DateTime.now().millisecondsSinceEpoch}',
      scriptId: json['scriptId'] as String? ?? '',
      anchorName: json['anchorName'] as String? ?? 'Anchor',
      feedbackNote: json['feedbackNote'] as String? ?? '',
      priority: json['priority'] as String? ?? 'medium',
      timestamp: (json['timestamp'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      status: json['status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'scriptId': scriptId,
      'anchorName': anchorName,
      'feedbackNote': feedbackNote,
      'priority': priority,
      'timestamp': timestamp,
      'status': status,
    };
  }
}

class ScriptModel {
  final String id;
  final String type; // 'opening' | 'speaker_intro' | 'transition' | 'closing' | 'announcement'
  final String title;
  final String? speakerName;
  final String? timeSlot;
  final int durationMinutes;
  final String status; // 'approved' | 'pending' | 'revised'
  final String? itemId;
  final String text;
  final String? tone; // 'Formal' | 'Casual' | 'Motivational' | 'Visionary'
  final String? targetAudience;
  final String? organizerApprovedName;
  final String? organizerApprovedAvatarUrl;
  final String source; // 'ai' | 'template' | 'manual'
  final String? provider; // 'gemini' | 'groq' | 'nvidia' | 'openrouter' | 'template' | 'manual'
  final int version;
  final String createdBy;
  final int createdAt;
  final int lastUpdated;
  final bool isNew;
  final bool isUpdated;
  final bool isReviewedByAnchor;
  final bool viewedByAnchor;
  final int? viewedAt;
  final int usageCount;
  final List<ScriptModificationRequest> modificationRequests;

  ScriptModel({
    required this.id,
    required this.type,
    String? title,
    this.speakerName,
    this.timeSlot,
    this.durationMinutes = 5,
    this.status = 'approved',
    this.itemId,
    required this.text,
    this.tone = 'Motivational',
    this.targetAudience = 'All Attendees',
    this.organizerApprovedName = 'Alex Rivera',
    this.organizerApprovedAvatarUrl,
    required this.source,
    this.provider,
    this.version = 1,
    required this.createdBy,
    required this.createdAt,
    int? lastUpdated,
    this.isNew = false,
    this.isUpdated = false,
    this.isReviewedByAnchor = false,
    this.viewedByAnchor = false,
    this.viewedAt,
    this.usageCount = 0,
    this.modificationRequests = const [],
  })  : title = title ?? _defaultTitle(type, speakerName),
        lastUpdated = lastUpdated ?? createdAt;

  static String _defaultTitle(String type, String? speakerName) {
    if (type == 'speaker_intro' && speakerName != null && speakerName.isNotEmpty) {
      return speakerName;
    }
    switch (type) {
      case 'opening':
        return 'Opening';
      case 'speaker_intro':
        return speakerName ?? 'Speaker Intro';
      case 'transition':
        return 'Transition';
      case 'closing':
        return 'Closing';
      case 'announcement':
        return 'Announcement';
      default:
        return 'Stage Script';
    }
  }

  // Helper getters for presentation
  int get wordCount {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  double get readingTimeMinutes {
    final words = wordCount;
    if (words == 0) return 0.0;
    return (words / 130).clamp(0.2, 99.0);
  }

  String get readingTimeFormatted {
    final minutes = readingTimeMinutes;
    if (minutes < 0.5) return '< 30 sec read';
    if (minutes < 1.0) return '~45 sec read';
    return '${minutes.toStringAsFixed(1)} min read';
  }

  String previewText([int maxChars = 50]) {
    final cleaned = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.length <= maxChars) return cleaned;
    return '${cleaned.substring(0, maxChars)}...';
  }

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';
  bool get isRevised => status == 'revised';

  Color get badgeColor {
    switch (type) {
      case 'opening':
        return const Color(0xFF2563EB); // Blue
      case 'speaker_intro':
        return const Color(0xFF7C5CFC); // Purple
      case 'transition':
        return const Color(0xFF10B981); // Green
      case 'closing':
        return const Color(0xFFF97316); // Orange
      case 'announcement':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF4E6BEB);
    }
  }

  String get typeLabel {
    switch (type) {
      case 'opening':
        return 'Opening';
      case 'speaker_intro':
        return 'Speaker Intro';
      case 'transition':
        return 'Transition';
      case 'closing':
        return 'Closing';
      case 'announcement':
        return 'Announcement';
      default:
        return type.toUpperCase();
    }
  }

  ScriptModel copyWith({
    String? id,
    String? type,
    String? title,
    String? speakerName,
    String? timeSlot,
    int? durationMinutes,
    String? status,
    String? itemId,
    String? text,
    String? tone,
    String? targetAudience,
    String? organizerApprovedName,
    String? organizerApprovedAvatarUrl,
    String? source,
    String? provider,
    int? version,
    String? createdBy,
    int? createdAt,
    int? lastUpdated,
    bool? isNew,
    bool? isUpdated,
    bool? isReviewedByAnchor,
    bool? viewedByAnchor,
    int? viewedAt,
    int? usageCount,
    List<ScriptModificationRequest>? modificationRequests,
  }) {
    return ScriptModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      speakerName: speakerName ?? this.speakerName,
      timeSlot: timeSlot ?? this.timeSlot,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      itemId: itemId ?? this.itemId,
      text: text ?? this.text,
      tone: tone ?? this.tone,
      targetAudience: targetAudience ?? this.targetAudience,
      organizerApprovedName: organizerApprovedName ?? this.organizerApprovedName,
      organizerApprovedAvatarUrl: organizerApprovedAvatarUrl ?? this.organizerApprovedAvatarUrl,
      source: source ?? this.source,
      provider: provider ?? this.provider,
      version: version ?? this.version,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isNew: isNew ?? this.isNew,
      isUpdated: isUpdated ?? this.isUpdated,
      isReviewedByAnchor: isReviewedByAnchor ?? this.isReviewedByAnchor,
      viewedByAnchor: viewedByAnchor ?? this.viewedByAnchor,
      viewedAt: viewedAt ?? this.viewedAt,
      usageCount: usageCount ?? this.usageCount,
      modificationRequests: modificationRequests ?? this.modificationRequests,
    );
  }

  factory ScriptModel.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'] as String? ?? 'opening';
    final rawSpeaker = json['speakerName'] as String?;
    final rawRequests = json['modificationRequests'] as List<dynamic>?;

    return ScriptModel(
      id: json['id'] as String? ?? '',
      type: rawType,
      title: json['title'] as String? ?? _defaultTitle(rawType, rawSpeaker),
      speakerName: rawSpeaker,
      timeSlot: json['timeSlot'] as String?,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 5,
      status: json['status'] as String? ?? 'approved',
      itemId: json['itemId'] as String?,
      text: json['text'] as String? ?? '',
      tone: json['tone'] as String? ?? 'Motivational',
      targetAudience: json['targetAudience'] as String? ?? 'All Attendees',
      organizerApprovedName: json['organizerApprovedName'] as String? ?? 'Alex Rivera',
      organizerApprovedAvatarUrl: json['organizerApprovedAvatarUrl'] as String?,
      source: json['source'] as String? ?? 'ai',
      provider: json['provider'] as String?,
      version: (json['version'] as num?)?.toInt() ?? 1,
      createdBy: json['createdBy'] as String? ?? 'system',
      createdAt: (json['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      lastUpdated: (json['lastUpdated'] as num?)?.toInt() ??
          (json['createdAt'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
      isNew: json['isNew'] as bool? ?? false,
      isUpdated: json['isUpdated'] as bool? ?? false,
      isReviewedByAnchor: json['isReviewedByAnchor'] as bool? ?? false,
      viewedByAnchor: json['viewedByAnchor'] as bool? ?? false,
      viewedAt: (json['viewedAt'] as num?)?.toInt(),
      usageCount: (json['usageCount'] as num?)?.toInt() ?? 0,
      modificationRequests: rawRequests != null
          ? rawRequests.map((r) => ScriptModificationRequest.fromJson(r as Map<String, dynamic>)).toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'speakerName': speakerName,
      'timeSlot': timeSlot,
      'durationMinutes': durationMinutes,
      'status': status,
      'itemId': itemId,
      'text': text,
      'tone': tone,
      'targetAudience': targetAudience,
      'organizerApprovedName': organizerApprovedName,
      'organizerApprovedAvatarUrl': organizerApprovedAvatarUrl,
      'source': source,
      'provider': provider,
      'version': version,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'lastUpdated': lastUpdated,
      'isNew': isNew,
      'isUpdated': isUpdated,
      'isReviewedByAnchor': isReviewedByAnchor,
      'viewedByAnchor': viewedByAnchor,
      'viewedAt': viewedAt,
      'usageCount': usageCount,
      'modificationRequests': modificationRequests.map((r) => r.toJson()).toList(),
    };
  }
}

