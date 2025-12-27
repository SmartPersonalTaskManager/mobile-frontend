import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sptm/core/constants.dart';
import 'package:sptm/models/weekly_stats.dart';
import 'package:sptm/models/task_item.dart';
import 'package:sptm/services/analytics_service.dart';
import 'package:sptm/services/task_service.dart';
import 'package:sptm/views/widgets/app_bar.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  int selectedPeriod = 0; // 0=Weekly,1=Monthly,2=Yearly

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      appBar: const SPTMAppBar(title: "Insights"),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStats,
          color: const Color(AppColors.primary),
          backgroundColor: const Color(AppColors.surface),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildStatsCards(),
                const SizedBox(height: 24),
                _buildActivityChart(),
                const SizedBox(height: 32),
                _buildMissionProgress(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // HEADER
  Widget _buildHeader() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("Weekly Analysis", style: TextStyle(color: Colors.white54)),
          ],
        ),
      ],
    );
  }

  bool _isLoading = true;
  WeeklyStats? _stats;
  final AnalyticsService _analyticsService = AnalyticsService();
  final TaskService _taskService = TaskService(); // Added TaskService

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(
      'userId',
    ); // Fixed key from 'user_id' to 'userId' to match ArchivePage
    if (userId == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. Fetch data in parallel
      final results = await Future.wait([
        _taskService.getTasks(userId),
        _analyticsService.getWeeklyStats(userId),
      ]);

      final allTasks = results[0] as List<TaskItem>;
      final serverStats = results[1] as WeeklyStats;

      // 2. Calculate local stats
      // Filter for tasks completed in the last 7 days (including today)
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekStart = today.subtract(const Duration(days: 6));

      // Activity Data (last 7 days)
      final List<int> activityData = List.filled(7, 0);

      int completedCount = 0;
      int totalCount = allTasks.length;

      for (var task in allTasks) {
        if (task.done && task.completedAt != null) {
          completedCount++;

          final cDate = task.completedAt!;
          final completedDay = DateTime(cDate.year, cDate.month, cDate.day);

          // Check if within the last 7 days window
          if (!completedDay.isBefore(weekStart) &&
              !completedDay.isAfter(today)) {
            final diff = completedDay.difference(weekStart).inDays;
            if (diff >= 0 && diff < 7) {
              activityData[diff]++;
            }
          }
        }
      }

      final double rate = totalCount > 0
          ? (completedCount / totalCount) * 100
          : 0.0;

      // 3. Merge with server stats (keep mission progress from server)
      final mergedStats = WeeklyStats(
        totalTasks: totalCount,
        completedTasks: completedCount,
        completionRate: rate,
        activityData: activityData,
        missionProgress: serverStats.missionProgress,
      );

      if (!mounted) return;
      setState(() {
        _stats = mergedStats;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading stats: $e");
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  // STATS
  Widget _buildStatsCards() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final completed = _stats?.completedTasks ?? 0;
    final rate = _stats?.completionRate ?? 0;

    return Row(
      children: [
        _statCard(
          title: "Tasks Completed",
          value: "$completed",
          delta: "", // Delta not available in API yet
          icon: Icons.check_circle,
          color: Colors.green,
        ),
        const SizedBox(width: 16),
        _statCard(
          title: "Completion Rate",
          value: "${rate.toStringAsFixed(1)}%",
          delta: "",
          icon: Icons.psychology,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required String delta,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(AppColors.surface),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color),
                ),
                const Spacer(),
                Text(delta, style: TextStyle(color: color)),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityChart() {
    if (_isLoading) return const SizedBox.shrink();

    /// 1️⃣ DATA GARANTİSİ
    final rawData = _stats?.activityData ?? [];
    final List<double> data = List.generate(
      7,
      (i) => i < rawData.length ? rawData[i].toDouble() : 0,
    );

    final spots = List.generate(7, (i) => FlSpot(i.toDouble(), data[i]));

    /// 2️⃣ SAFE maxY
    final maxY = data.reduce((a, b) => a > b ? a : b);
    final safeMaxY = maxY == 0 ? 5 : maxY + 1;

    final now = DateTime.now();
    final weekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    final days = List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      return weekDays[date.weekday - 1];
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(AppColors.surface),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Activity",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: safeMaxY.toDouble(),

                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: Colors.white10, strokeWidth: 1),
                ),

                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, _) {
                        final i = value.toInt();
                        if (i < 0 || i > 6) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            days[i],
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                borderData: FlBorderData(show: false),

                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: const Color(0xFF6C5CE7),
                    barWidth: 4,

                    /// 3️⃣ BULLET POINTLER
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, __, ___, ____) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: const Color(0xFF6C5CE7), // bullet
                          strokeWidth: 2,
                          strokeColor: Colors.white, // outline
                        );
                      },
                    ),

                    /// 4️⃣ ALT GRADIENT
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF6C5CE7).withOpacity(0.3),
                          const Color(0xFF6C5CE7).withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // MISSION PROGRESS
  Widget _buildMissionProgress() {
    final missions = _stats?.missionProgress ?? [];

    if (missions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Mission Progress",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...missions.map((m) {
          final color = _parseColor(m.color);
          return _progressItem(m.title, m.progress, color);
        }).toList(),
      ],
    );
  }

  Color _parseColor(String colorStr) {
    try {
      if (colorStr.startsWith("#")) {
        return Color(int.parse("0xFF" + colorStr.substring(1)));
      }
    } catch (e) {
      // ignore
    }
    return Colors.blue;
  }

  Widget _progressItem(String title, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(color: Colors.white)),
              const Spacer(),
              Text(
                "${(value * 100).toInt()}%",
                style: const TextStyle(color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation(color),
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      ),
    );
  }
}
