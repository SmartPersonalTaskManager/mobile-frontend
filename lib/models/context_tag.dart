class ContextTag {
  final int id;
  final String name;
  final String? icon;

  const ContextTag({required this.id, required this.name, this.icon});

  factory ContextTag.fromJson(Map<String, dynamic> json) {
    return ContextTag(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String?,
    );
  }
}
