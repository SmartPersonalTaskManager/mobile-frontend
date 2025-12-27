class CoreValue {
  final int id;
  final String text;
  final int userId;

  const CoreValue({
    required this.id,
    required this.text,
    required this.userId,
  });

  factory CoreValue.fromJson(Map<String, dynamic> json) {
    return CoreValue(
      id: (json['id'] as num).toInt(),
      text: json['text'] as String? ?? '',
      userId: (json['userId'] as num?)?.toInt() ?? 0,
    );
  }
}
