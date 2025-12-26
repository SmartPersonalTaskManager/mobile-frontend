import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sptm/core/constants.dart';
import 'package:sptm/models/mission.dart';
import 'package:sptm/models/task_item.dart';
import 'package:sptm/views/dashboard/widgets/task_card.dart';
import 'package:sptm/views/tasks/task_details_page.dart';

// TODO Implement mission detail funcstionalities:
//  must lead to task page of that submission

class MissionDetailPage extends StatelessWidget {
  final Mission mission;

  const MissionDetailPage({super.key, required this.mission});

  @override
  Widget build(BuildContext context) {
    // Assuming backend SubMission has title and description.
    // We map them to display.
    final submissions = mission.subMissions;

    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      appBar: AppBar(
        backgroundColor: const Color(AppColors.surface),
        iconTheme: const IconThemeData(color: Color(AppColors.textMain)),
        title: Text(
          mission.content,
          style: const TextStyle(color: Color(AppColors.textMain)),
        ),
      ),
      body: submissions.isEmpty
          ? const Center(
              child: Text(
                'No sub-missions yet.',
                style: TextStyle(color: Color(AppColors.textMuted)),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: submissions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final submission = submissions[index];
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(AppColors.surface),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SubMissionDetailPage(
                            subMissionTitle: submission.title,
                          ),
                        ),
                      );
                    },
                    title: Text(
                      submission.title,
                      style: const TextStyle(
                        color: Color(AppColors.textMain),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: submission.description != null
                        ? Text(
                            submission.description!,
                            style: const TextStyle(
                              color: Color(AppColors.textMuted),
                            ),
                          )
                        : null,
                    trailing: const Icon(
                      Icons.keyboard_arrow_right,
                      color: Color(AppColors.textMuted),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class SubMissionDetailPage extends StatefulWidget {
  final String subMissionTitle;

  const SubMissionDetailPage({super.key, required this.subMissionTitle});

  @override
  State<SubMissionDetailPage> createState() => _SubMissionDetailPageState();
}

class _SubMissionDetailPageState extends State<SubMissionDetailPage> {
  static const String _tasksKey = "dashboard_tasks";
  final List<TaskItem> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final rawItems = prefs.getStringList(_tasksKey) ?? [];
    final loadedTasks = <TaskItem>[];
    for (final raw in rawItems) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        loadedTasks.add(TaskItem.fromJson(decoded));
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _tasks
        ..clear()
        ..addAll(loadedTasks);
      _isLoading = false;
    });
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final payloads = _tasks.map((task) => jsonEncode(task.toJson())).toList();
    await prefs.setStringList(_tasksKey, payloads);
  }

  List<TaskItem> get _linkedTasks {
    return _tasks
        .where((task) => task.mission == widget.subMissionTitle)
        .toList();
  }

  String _formatDate(DateTime value) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    final month = months[value.month - 1];
    return "$month ${value.day.toString().padLeft(2, "0")}";
  }

  @override
  Widget build(BuildContext context) {
    final linkedTasks = _linkedTasks;
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      appBar: AppBar(
        backgroundColor: const Color(AppColors.surface),
        iconTheme: const IconThemeData(color: Color(AppColors.textMain)),
        title: Text(
          widget.subMissionTitle,
          style: const TextStyle(color: Color(AppColors.textMain)),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: const Color(AppColors.primary),
          backgroundColor: const Color(AppColors.background),
          onRefresh: _loadTasks,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(AppColors.primary),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(AppColors.surface),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Sub-mission Overview",
                            style: TextStyle(
                              color: Color(AppColors.textMuted),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.subMissionTitle,
                            style: const TextStyle(
                              color: Color(AppColors.textMain),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "${linkedTasks.length} task${linkedTasks.length == 1 ? "" : "s"} linked",
                            style: const TextStyle(
                              color: Color(AppColors.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Tasks",
                      style: TextStyle(
                        color: Color(AppColors.textMain),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (linkedTasks.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Text(
                            "No tasks linked to this sub-mission yet.",
                            style: TextStyle(color: Color(AppColors.textMuted)),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      ...linkedTasks.map((TaskItem task) {
                        final String missionTitle =
                            task.mission ?? "No Mission";
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => TaskDetailsPage(
                                    title: task.title,
                                    submission: missionTitle,
                                    dueDate: task.dueDate,
                                    context: task.context,
                                    onDelete: () {
                                      setState(() {
                                        _tasks.remove(task);
                                      });
                                      _saveTasks();
                                    },
                                  ),
                                ),
                              );
                            },
                            child: TaskCard(
                              title: task.title,
                              subtitle:
                                  "${task.context ?? "No context"} · ${task.dueDate != null ? _formatDate(task.dueDate!) : "No date"}",
                              done: task.done,
                            ),
                          ),
                        );
                      }),
                  ],
                ),
        ),
      ),
    );
  }
}
