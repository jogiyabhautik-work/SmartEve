class LiveStateModel {
  final String status; // 'draft' | 'live' | 'completed'
  final String? currentItemId;
  final int? startedAt;
  final int totalDelayMin;

  LiveStateModel({
    required this.status,
    this.currentItemId,
    this.startedAt,
    this.totalDelayMin = 0,
  });

  factory LiveStateModel.fromJson(Map<String, dynamic> json) {
    return LiveStateModel(
      status: json['status'] as String? ?? 'draft',
      currentItemId: json['currentItemId'] as String?,
      startedAt: (json['startedAt'] as num?)?.toInt(),
      totalDelayMin: (json['totalDelayMin'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'currentItemId': currentItemId,
      'startedAt': startedAt,
      'totalDelayMin': totalDelayMin,
    };
  }
}

class EventModel {
  final String id;
  final String name;
  final String type;
  final String date;
  final String venue;
  final String tone;
  final String description;
  final String ownerId;
  final String joinCode;
  final List<String> anchorIds;
  final LiveStateModel liveState;
  final int createdAt;

  EventModel({
    required this.id,
    required this.name,
    required this.type,
    required this.date,
    required this.venue,
    required this.tone,
    this.description = '',
    required this.ownerId,
    required this.joinCode,
    this.anchorIds = const [],
    required this.liveState,
    required this.createdAt,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Untitled Event',
      type: json['type'] as String? ?? 'Conference',
      date: json['date'] as String? ?? '',
      venue: json['venue'] as String? ?? '',
      tone: json['tone'] as String? ?? 'Professional',
      description: json['description'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      joinCode: json['joinCode'] as String? ?? '',
      anchorIds: (json['anchorIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      liveState: json['liveState'] != null
          ? LiveStateModel.fromJson(json['liveState'] as Map<String, dynamic>)
          : LiveStateModel(status: 'draft'),
      createdAt: (json['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'date': date,
      'venue': venue,
      'tone': tone,
      'description': description,
      'ownerId': ownerId,
      'joinCode': joinCode,
      'anchorIds': anchorIds,
      'liveState': liveState.toJson(),
      'createdAt': createdAt,
    };
  }
}
