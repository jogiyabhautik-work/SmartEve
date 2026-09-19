class AgendaItemModel {
  final String id;
  final int order;
  final String title;
  final String type; // 'opening', 'keynote', 'talk', 'panel', 'break', 'workshop', 'announcement', 'closing'
  final List<String> speakerIds;
  final int duration; // in minutes
  final String plannedStart;
  final String startTime;
  final String endTime;
  final String status; // 'upcoming', 'live', 'done', 'cancelled', 'skipped'
  final bool absorbable;
  final int? minDuration;
  final bool hardStart;
  final String? notes;

  AgendaItemModel({
    required this.id,
    required this.order,
    required this.title,
    required this.type,
    this.speakerIds = const [],
    required this.duration,
    required this.plannedStart,
    required this.startTime,
    required this.endTime,
    this.status = 'upcoming',
    this.absorbable = false,
    this.minDuration,
    this.hardStart = false,
    this.notes,
  });

  bool get isLive => status == 'live';
  bool get isDone => status == 'done';
  bool get isUpcoming => status == 'upcoming';
  bool get isBreak => type == 'break';

  factory AgendaItemModel.fromJson(Map<String, dynamic> json) {
    return AgendaItemModel(
      id: json['id'] as String? ?? '',
      order: (json['order'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? 'Untitled Session',
      type: json['type'] as String? ?? 'talk',
      speakerIds: (json['speakerIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      duration: (json['duration'] as num?)?.toInt() ?? 15,
      plannedStart: json['plannedStart'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      status: json['status'] as String? ?? 'upcoming',
      absorbable: json['absorbable'] as bool? ?? false,
      minDuration: (json['minDuration'] as num?)?.toInt(),
      hardStart: json['hardStart'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': order,
      'title': title,
      'type': type,
      'speakerIds': speakerIds,
      'duration': duration,
      'plannedStart': plannedStart,
      'startTime': startTime,
      'endTime': endTime,
      'status': status,
      'absorbable': absorbable,
      'minDuration': minDuration,
      'hardStart': hardStart,
      'notes': notes,
    };
  }
}
