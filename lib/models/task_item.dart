class TaskItem {
  final int id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final bool urgent;
  final bool important;
  final String? context;
  final bool isInbox;
  final bool isArchived;
  final DateTime? completedAt;
  final String? mission; // For UI display, might not be in basic DTO yet
  final bool done; // Helper for UI, derived from status or completedAt

  TaskItem({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.urgent = false,
    this.important = false,
    this.context,
    this.isInbox = true,
    this.isArchived = false,
    this.completedAt,
    this.mission,
    this.done = false,
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    // Priority logic
    final priority = json['priority'] as String?;
    final u = priority?.contains("URGENT") ?? false;
    // Check if starts with NOT_URGENT -> urgent=false
    // if starts with URGENT -> urgent=true
    final isUrgent = priority != null && !priority.startsWith("NOT_URGENT");
    final isImportant =
        priority?.contains("IMPORTANT") == true &&
        !priority!.endsWith("NOT_IMPORTANT");

    // Status logic
    final status = json['status'] as String?;
    final isDone = status == "COMPLETED";

    return TaskItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      urgent: isUrgent,
      important: isImportant,
      context: json['context'],
      isInbox: json['isInbox'] ?? true,
      isArchived: json['isArchived'] ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      mission: json['missionName'],
      done: isDone,
    );
  }

  TaskItem copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? dueDate,
    bool? urgent,
    bool? important,
    String? context,
    bool? isInbox,
    bool? isArchived,
    DateTime? completedAt,
    String? mission,
    bool? done,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      urgent: urgent ?? this.urgent,
      important: important ?? this.important,
      context: context ?? this.context,
      isInbox: isInbox ?? this.isInbox,
      isArchived: isArchived ?? this.isArchived,
      completedAt: completedAt ?? this.completedAt,
      mission: mission ?? this.mission,
      done: done ?? this.done,
    );
  }

  Map<String, dynamic> toJson() {
    String priorityVal;
    if (urgent && important) {
      priorityVal = "URGENT_IMPORTANT";
    } else if (!urgent && important) {
      priorityVal = "NOT_URGENT_IMPORTANT";
    } else if (urgent && !important) {
      priorityVal = "URGENT_NOT_IMPORTANT";
    } else {
      priorityVal = "NOT_URGENT_NOT_IMPORTANT";
    }

    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'priority': priorityVal,
      'status': done ? "COMPLETED" : "NOT_STARTED",
      'context': context,
      'isInbox': isInbox,
      'isArchived': isArchived,
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}
