class ScriptModel {
  final String id;
  final String type;
  final String? itemId;
  final String text;
  final String source; // 'ai' | 'template' | 'manual'
  final String? provider; // 'gemini' | 'groq' | 'template' | 'manual'
  final int version;
  final String createdBy;
  final int createdAt;

  ScriptModel({
    required this.id,
    required this.type,
    this.itemId,
    required this.text,
    required this.source,
    this.provider,
    this.version = 1,
    required this.createdBy,
    required this.createdAt,
  });

  factory ScriptModel.fromJson(Map<String, dynamic> json) {
    return ScriptModel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'opening',
      itemId: json['itemId'] as String?,
      text: json['text'] as String? ?? '',
      source: json['source'] as String? ?? 'ai',
      provider: json['provider'] as String?,
      version: (json['version'] as num?)?.toInt() ?? 1,
      createdBy: json['createdBy'] as String? ?? 'system',
      createdAt: (json['createdAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'itemId': itemId,
      'text': text,
      'source': source,
      'provider': provider,
      'version': version,
      'createdBy': createdBy,
      'createdAt': createdAt,
    };
  }
}
