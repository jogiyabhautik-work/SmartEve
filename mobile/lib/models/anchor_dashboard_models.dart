import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

enum AnchorEventStatus {
  invited,
  accepted,
  active,
  completed,
}

extension AnchorEventStatusExtension on AnchorEventStatus {
  String get label {
    switch (this) {
      case AnchorEventStatus.invited:
        return 'INVITED';
      case AnchorEventStatus.accepted:
        return 'ACCEPTED';
      case AnchorEventStatus.active:
        return 'LIVE / ACTIVE';
      case AnchorEventStatus.completed:
        return 'COMPLETED';
    }
  }

  Color get color {
    switch (this) {
      case AnchorEventStatus.active:
        return AppTheme.success;
      case AnchorEventStatus.accepted:
        return AppTheme.primaryBlue;
      case AnchorEventStatus.invited:
        return AppTheme.warning;
      case AnchorEventStatus.completed:
        return AppTheme.textSecondary;
    }
  }

  Color get backgroundColor {
    return color.withValues(alpha: 0.12);
  }
}

class AnchorInvitation {
  final String id;
  final String eventId;
  final String title;
  final String eventType;
  final String organizerName;
  final String collegeName;
  final String date;
  final String time;
  final String invitedAt;
  final String venue;
  final String description;

  const AnchorInvitation({
    required this.id,
    required this.eventId,
    required this.title,
    required this.eventType,
    required this.organizerName,
    required this.collegeName,
    required this.date,
    required this.time,
    required this.invitedAt,
    required this.venue,
    required this.description,
  });

  factory AnchorInvitation.fromJson(Map<String, dynamic> json) {
    return AnchorInvitation(
      id: json['id'] as String? ?? '',
      eventId: json['eventId'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled Event',
      eventType: json['eventType'] as String? ?? 'Conference',
      organizerName: json['organizerName'] as String? ?? 'Event Organizer',
      collegeName: json['collegeName'] as String? ?? 'Main Campus',
      date: json['date'] as String? ?? '',
      time: json['time'] as String? ?? '',
      invitedAt: json['invitedAt'] as String? ?? 'Just now',
      venue: json['venue'] as String? ?? 'Auditorium',
      description: json['description'] as String? ?? '',
    );
  }
}

class AnchorAnalyticsData {
  final int stageTimeMinutes;
  final int audienceCount;
  final double scriptCompletionRate;
  final int audienceRatingPercent;

  const AnchorAnalyticsData({
    required this.stageTimeMinutes,
    required this.audienceCount,
    required this.scriptCompletionRate,
    required this.audienceRatingPercent,
  });
}

class AnchorEventCardItem {
  final String id;
  final String title;
  final String eventType;
  final String date;
  final String time;
  final String organizerName;
  final String collegeName;
  final AnchorEventStatus status;
  final String joinCode;
  final String venue;
  final String duration;
  final String? recapSummary;
  final AnchorAnalyticsData? analytics;

  const AnchorEventCardItem({
    required this.id,
    required this.title,
    required this.eventType,
    required this.date,
    required this.time,
    required this.organizerName,
    required this.collegeName,
    required this.status,
    required this.joinCode,
    required this.venue,
    required this.duration,
    this.recapSummary,
    this.analytics,
  });

  AnchorEventCardItem copyWith({
    AnchorEventStatus? status,
  }) {
    return AnchorEventCardItem(
      id: id,
      title: title,
      eventType: eventType,
      date: date,
      time: time,
      organizerName: organizerName,
      collegeName: collegeName,
      status: status ?? this.status,
      joinCode: joinCode,
      venue: venue,
      duration: duration,
      recapSummary: recapSummary,
      analytics: analytics,
    );
  }
}
