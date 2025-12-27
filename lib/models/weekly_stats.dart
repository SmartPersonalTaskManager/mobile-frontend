class MissionProgress {
  final String title;
  final double progress;
  final String color;

  MissionProgress({
    required this.title,
    required this.progress,
    required this.color,
  });

  factory MissionProgress.fromJson(Map<String, dynamic> json) {
    return MissionProgress(
      title: json['title'] ?? '',
      progress: (json['progress'] ?? 0).toDouble(),
      color: json['color'] ?? '#FFFFFF',
    );
  }
}

class WeeklyStats {
  final int totalTasks;
  final int completedTasks;
  final double completionRate;
  final List<int> activityData;
  final List<MissionProgress> missionProgress;

  WeeklyStats({
    required this.totalTasks,
    required this.completedTasks,
    required this.completionRate,
    required this.activityData,
    required this.missionProgress,
  });

  factory WeeklyStats.fromJson(Map<String, dynamic> json) {
    return WeeklyStats(
      totalTasks: json['totalTasks'] ?? 0,
      completedTasks: json['completedTasks'] ?? 0,
      completionRate: (json['completionRate'] ?? 0).toDouble(),
      activityData:
          (json['activityData'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      missionProgress:
          (json['missionProgress'] as List<dynamic>?)
              ?.map((e) => MissionProgress.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
