class NotificationModel {
  final String id;
  final String type;
  final String message;
  final String createdBy;
  final int createdAt;
  final String priority; // 'normal' | 'high' | 'urgent'
  final bool read;

  NotificationModel({
    required this.id,
    required this.type,
    required this.message,
    required this.createdBy,
    required this.createdAt,
    this.priority = 'normal',
    this.read = false,
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
    };
  }
}
