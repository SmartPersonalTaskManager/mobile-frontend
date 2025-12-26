class SubMission {
  final int id;
  final String title;
  final String description;

  const SubMission({
    required this.id,
    required this.title,
    required this.description,
  });

  factory SubMission.fromJson(Map<String, dynamic> json) {
    return SubMission(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

class Mission {
  final int id;
  final String content;
  final int version;
  final int userId;
  final List<SubMission> subMissions;

  const Mission({
    required this.id,
    required this.content,
    required this.version,
    required this.userId,
    required this.subMissions,
  });

  factory Mission.fromJson(Map<String, dynamic> json) {
    final subMissionsJson =
        (json['subMissions'] as List<dynamic>? ?? <dynamic>[]);
    return Mission(
      id: (json['id'] as num).toInt(),
      content: json['content'] as String? ?? '',
      version: (json['version'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      subMissions: subMissionsJson
          .map((item) => SubMission.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
