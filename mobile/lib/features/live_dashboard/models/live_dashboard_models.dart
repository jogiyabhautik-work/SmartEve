import 'package:flutter/material.dart';

enum ScheduleDriftStatus {
  onSchedule,
  runningBehind,
  significantlyDelayed;

  String get label {
    switch (this) {
      case ScheduleDriftStatus.onSchedule:
        return "On Schedule";
      case ScheduleDriftStatus.runningBehind:
        return "Running Behind";
      case ScheduleDriftStatus.significantlyDelayed:
        return "Significantly Delayed";
    }
  }

  Color get color {
    switch (this) {
      case ScheduleDriftStatus.onSchedule:
        return const Color(0xFF10B981); // green
      case ScheduleDriftStatus.runningBehind:
        return const Color(0xFFF59E0B); // yellow/amber (< 5 mins)
      case ScheduleDriftStatus.significantlyDelayed:
        return const Color(0xFFEF4444); // red (> 5 mins)
    }
  }

  IconData get icon {
    switch (this) {
      case ScheduleDriftStatus.onSchedule:
        return Icons.check_circle_rounded;
      case ScheduleDriftStatus.runningBehind:
        return Icons.schedule_rounded;
      case ScheduleDriftStatus.significantlyDelayed:
        return Icons.warning_amber_rounded;
    }
  }

  /// Legacy aliases so existing call-sites keep compiling.
  static ScheduleDriftStatus get onTrack => ScheduleDriftStatus.onSchedule;
  static ScheduleDriftStatus get behindSchedule =>
      ScheduleDriftStatus.significantlyDelayed;
  static ScheduleDriftStatus get aheadOfSchedule =>
      ScheduleDriftStatus.onSchedule;
}

class LiveSpeakerInfo {
  final String id;
  final String name;
  final String? topic;
  final String? designation;
  final String? organization;
  final String? photoUrl;
  final String? bio;

  const LiveSpeakerInfo({
    required this.id,
    required this.name,
    this.topic,
    this.designation,
    this.organization,
    this.photoUrl,
    this.bio,
  });

  factory LiveSpeakerInfo.fromJson(Map<String, dynamic> json) {
    return LiveSpeakerInfo(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Featured Speaker',
      topic: json['topic']?.toString(),
      designation: json['designation']?.toString(),
      organization: json['organization']?.toString(),
      photoUrl: json['photoUrl']?.toString() ?? json['photo_url']?.toString(),
      bio: json['bio']?.toString(),
    );
  }
}

class LiveActivityItem {
  final String id;
  final String title;
  final String type;
  final String? description;
  final int durationMinutes;
  final String? startTime;
  final String? endTime;
  final String status;
  final LiveSpeakerInfo? speaker;
  final String? notes;

  const LiveActivityItem({
    required this.id,
    required this.title,
    required this.type,
    this.description,
    required this.durationMinutes,
    this.startTime,
    this.endTime,
    required this.status,
    this.speaker,
    this.notes,
  });

  factory LiveActivityItem.fromJson(Map<String, dynamic> json) {
    LiveSpeakerInfo? spk;
    if (json['speaker'] is Map<String, dynamic>) {
      spk = LiveSpeakerInfo.fromJson(json['speaker'] as Map<String, dynamic>);
    } else if (json['speaker_name'] != null || json['speakerName'] != null) {
      spk = LiveSpeakerInfo(
        id: json['speaker_id']?.toString() ?? 'spk-1',
        name: json['speaker_name']?.toString() ?? json['speakerName']?.toString() ?? '',
        topic: json['speaker_topic']?.toString() ?? json['speakerTopic']?.toString(),
        designation: json['speaker_designation']?.toString() ?? json['speakerDesignation']?.toString(),
        organization: json['speaker_organization']?.toString() ?? json['speakerOrganization']?.toString(),
        photoUrl: json['speaker_photo']?.toString() ?? json['speakerPhoto']?.toString(),
      );
    }

    return LiveActivityItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Stage Activity',
      type: json['type']?.toString() ?? 'activity',
      description: json['description']?.toString() ?? json['notes']?.toString(),
      durationMinutes: int.tryParse(json['durationMinutes']?.toString() ?? json['duration_minutes']?.toString() ?? '') ?? 15,
      startTime: json['startTime']?.toString() ?? json['start_time']?.toString(),
      endTime: json['endTime']?.toString() ?? json['end_time']?.toString(),
      status: json['status']?.toString() ?? 'scheduled',
      speaker: spk,
      notes: json['notes']?.toString(),
    );
  }

  LiveActivityItem copyWith({
    String? title,
    String? type,
    String? description,
    int? durationMinutes,
    String? status,
    LiveSpeakerInfo? speaker,
  }) {
    return LiveActivityItem(
      id: id,
      title: title ?? this.title,
      type: type ?? this.type,
      description: description ?? this.description,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      startTime: startTime,
      endTime: endTime,
      status: status ?? this.status,
      speaker: speaker ?? this.speaker,
      notes: notes,
    );
  }
}

class LiveAudienceMetrics {
  final int activeAttendees;
  final int questionsCount;
  final Map<String, int> reactions;

  const LiveAudienceMetrics({
    this.activeAttendees = 142,
    this.questionsCount = 18,
    this.reactions = const {
      'thumbsUp': 56,
      'heart': 84,
      'applause': 120,
      'rocket': 45,
      'fire': 67,
    },
  });

  factory LiveAudienceMetrics.fromJson(Map<String, dynamic> json) {
    Map<String, int> rx = {};
    if (json['reactions'] is Map) {
      final rMap = json['reactions'] as Map;
      rMap.forEach((k, v) {
        rx[k.toString()] = int.tryParse(v.toString()) ?? 0;
      });
    } else {
      rx = {
        'thumbsUp': 56,
        'heart': 84,
        'applause': 120,
        'rocket': 45,
        'fire': 67,
      };
    }

    return LiveAudienceMetrics(
      activeAttendees: int.tryParse(json['activeAttendees']?.toString() ?? '') ?? 142,
      questionsCount: int.tryParse(json['questionsCount']?.toString() ?? '') ?? 18,
      reactions: rx,
    );
  }

  LiveAudienceMetrics copyWithReaction(String key) {
    final updated = Map<String, int>.from(reactions);
    updated[key] = (updated[key] ?? 0) + 1;
    return LiveAudienceMetrics(
      activeAttendees: activeAttendees,
      questionsCount: questionsCount,
      reactions: updated,
    );
  }
}

class LiveModeratorInfo {
  final String name;
  final String role;
  final bool isOnline;
  final String? avatarUrl;

  const LiveModeratorInfo({
    required this.name,
    required this.role,
    this.isOnline = true,
    this.avatarUrl,
  });
}

class LiveOrganizerContact {
  final String name;
  final String phone;
  final String email;
  final String? avatarUrl;

  const LiveOrganizerContact({
    required this.name,
    required this.phone,
    required this.email,
    this.avatarUrl,
  });

  factory LiveOrganizerContact.fromJson(Map<String, dynamic> json) {
    return LiveOrganizerContact(
      name: json['name']?.toString() ?? 'Romal Tandel',
      phone: json['phone']?.toString() ?? '+91 98765 43210',
      email: json['email']?.toString() ?? 'romaltandel1264@gmail.com',
      avatarUrl: json['avatarUrl']?.toString() ?? json['avatar_url']?.toString(),
    );
  }
}

class LiveScriptSnippet {
  final String id;
  final String title;
  final String type;
  final String content;
  final bool isApproved;
  final String? tone;

  const LiveScriptSnippet({
    required this.id,
    required this.title,
    required this.type,
    required this.content,
    this.isApproved = true,
    this.tone,
  });

  factory LiveScriptSnippet.fromJson(Map<String, dynamic> json) {
    return LiveScriptSnippet(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Stage Script',
      type: json['type']?.toString() ?? json['script_type']?.toString() ?? 'opening',
      content: json['content']?.toString() ?? '',
      isApproved: json['isApproved'] == true || json['is_approved'] == true,
      tone: json['tone']?.toString(),
    );
  }
}

class StageMessage {
  final String id;
  final String senderName;
  final String senderRole;
  final String message;
  final DateTime timestamp;
  final bool isUrgent;

  const StageMessage({
    required this.id,
    required this.senderName,
    required this.senderRole,
    required this.message,
    required this.timestamp,
    this.isUrgent = false,
  });
}
