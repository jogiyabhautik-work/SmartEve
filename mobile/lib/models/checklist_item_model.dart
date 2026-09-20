import 'package:flutter/material.dart';

class ChecklistItemModel {
  final String id;
  final String itemKey;
  final String label;
  final IconData icon;
  final int orderIndex;
  bool isCompleted;
  int? completedAt;

  ChecklistItemModel({
    required this.id,
    required this.itemKey,
    required this.label,
    required this.icon,
    this.orderIndex = 0,
    this.isCompleted = false,
    this.completedAt,
  });

  factory ChecklistItemModel.fromJson(Map<String, dynamic> json) {
    return ChecklistItemModel(
      id: json['id'] as String? ?? '',
      itemKey: json['itemKey'] as String? ?? json['item_key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      icon: checklistIconFor(json['itemKey'] as String? ?? json['item_key'] as String? ?? ''),
      orderIndex: (json['orderIndex'] as num?)?.toInt() ?? (json['order_index'] as num?)?.toInt() ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? json['is_completed'] as bool? ?? false,
      completedAt: (json['completedAt'] as num?)?.toInt() ?? (json['completed_at'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemKey': itemKey,
      'label': label,
      'orderIndex': orderIndex,
      'isCompleted': isCompleted,
      'completedAt': completedAt,
    };
  }
}

/// Maps checklist item keys to display icons (kept out of the model so the
/// model stays JSON-serializable without IconData encoding).
IconData checklistIconFor(String key) {
  switch (key) {
    case 'review_speakers':
      return Icons.people_alt_outlined;
    case 'memorize_opening':
      return Icons.record_voice_over_outlined;
    case 'check_audio':
      return Icons.mic_none_rounded;
    case 'check_video':
      return Icons.videocam_outlined;
    case 'review_scripts':
      return Icons.description_outlined;
    case 'agenda_flow':
      return Icons.timeline_rounded;
    case 'check_internet':
      return Icons.wifi_rounded;
    case 'notify_organizer':
      return Icons.send_outlined;
    default:
      return Icons.check_circle_outline;
  }
}
