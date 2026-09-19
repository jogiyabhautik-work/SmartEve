class SpeakerModel {
  final String id;
  final String name;
  final String designation;
  final String organization;
  final String topic;
  final String bio;
  final List<String> highlights;
  final String? photoUrl;
  final String status; // 'expected' | 'arrived' | 'absent'

  SpeakerModel({
    required this.id,
    required this.name,
    required this.designation,
    required this.organization,
    required this.topic,
    required this.bio,
    this.highlights = const [],
    this.photoUrl,
    this.status = 'expected',
  });

  factory SpeakerModel.fromJson(Map<String, dynamic> json) {
    return SpeakerModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unnamed Speaker',
      designation: json['designation'] as String? ?? '',
      organization: json['organization'] as String? ?? '',
      topic: json['topic'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      highlights: (json['highlights'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      photoUrl: json['photoUrl'] as String?,
      status: json['status'] as String? ?? 'expected',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'designation': designation,
      'organization': organization,
      'topic': topic,
      'bio': bio,
      'highlights': highlights,
      'photoUrl': photoUrl,
      'status': status,
    };
  }
}
