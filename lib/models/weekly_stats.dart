class WeeklyStats {
  final int totalTasks;
  final int completedTasks;
  final double completionRate;

  WeeklyStats({
    required this.totalTasks,
    required this.completedTasks,
    required this.completionRate,
  });

  factory WeeklyStats.fromJson(Map<String, dynamic> json) {
    return WeeklyStats(
      totalTasks: json['totalTasks'] ?? 0,
      completedTasks: json['completedTasks'] ?? 0,
      completionRate: (json['completionRate'] ?? 0).toDouble(),
    );
  }
}
