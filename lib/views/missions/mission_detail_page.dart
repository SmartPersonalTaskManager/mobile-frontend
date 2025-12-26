import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sptm/core/constants.dart';
import 'package:sptm/models/mission.dart';
import 'package:sptm/models/task_item.dart';
import 'package:sptm/services/mission_service.dart';
import 'package:sptm/views/dashboard/widgets/task_card.dart';
import 'package:sptm/views/tasks/task_details_page.dart';

// TODO Implement mission detail funcstionalities:
//  must lead to task page of that submission

class MissionDetailPage extends StatefulWidget {
  final Mission mission;

  const MissionDetailPage({super.key, required this.mission});

  @override
  State<MissionDetailPage> createState() => _MissionDetailPageState();
}

class _MissionDetailPageState extends State<MissionDetailPage> {
  final MissionService _missionService = MissionService();
  final List<SubMission> _subMissions = [];
  bool _isSaving = false;
  bool _isUpdatingTitle = false;
  String _missionTitle = '';

  @override
  void initState() {
    super.initState();
    _subMissions
      ..clear()
      ..addAll(widget.mission.subMissions);
    _missionTitle = widget.mission.content;
  }

  Future<void> _showEditMissionDialog() async {
    if (_isUpdatingTitle) return;
    final controller = TextEditingController(text: _missionTitle);

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(AppColors.surface),
          title: const Text(
            'Edit Mission',
            style: TextStyle(color: Color(AppColors.textMain)),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            style: const TextStyle(color: Color(AppColors.textMain)),
            decoration: const InputDecoration(
              hintText: 'Mission title',
              hintStyle: TextStyle(color: Color(AppColors.textMuted)),
            ),
            onSubmitted: (_) => Navigator.of(context).pop(controller.text),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    final title = result?.trim();
    if (title == null || title.isEmpty || title == _missionTitle) {
      return;
    }

    setState(() => _isUpdatingTitle = true);
    try {
      final updated = await _missionService.updateMission(
        widget.mission.id,
        title,
      );
      if (!mounted) return;
      setState(() {
        _missionTitle = updated.content;
        _isUpdatingTitle = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUpdatingTitle = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update mission: $e')));
    }
  }

  Future<void> _showAddSubMissionDialog() async {
    if (_isSaving) return;
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(AppColors.surface),
          title: const Text(
            'Add Sub-mission',
            style: TextStyle(color: Color(AppColors.textMain)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                textInputAction: TextInputAction.next,
                style: const TextStyle(color: Color(AppColors.textMain)),
                decoration: const InputDecoration(
                  hintText: 'Title',
                  hintStyle: TextStyle(color: Color(AppColors.textMuted)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                textInputAction: TextInputAction.done,
                style: const TextStyle(color: Color(AppColors.textMain)),
                decoration: const InputDecoration(
                  hintText: 'Description (optional)',
                  hintStyle: TextStyle(color: Color(AppColors.textMuted)),
                ),
                minLines: 2,
                maxLines: 4,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    final shouldSave = result ?? false;
    if (!shouldSave) return;

    final title = titleController.text.trim();
    if (title.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a title.')));
      return;
    }

    final description = descriptionController.text.trim();

    setState(() => _isSaving = true);
    try {
      final created = await _missionService.addSubMission(
        widget.mission.id,
        title,
        description,
      );
      if (!mounted) return;
      setState(() {
        _subMissions.add(created);
        _isSaving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add sub-mission: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Assuming backend SubMission has title and description.
    // We map them to display.
    final submissions = _subMissions;

    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      appBar: AppBar(
        backgroundColor: const Color(AppColors.background),
        iconTheme: const IconThemeData(color: Color(AppColors.textMain)),
        title: Text(
          _missionTitle,
          style: const TextStyle(
            color: Color(AppColors.textMain),
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Color(AppColors.textMain)),
            onPressed: _isUpdatingTitle ? null : _showEditMissionDialog,
            tooltip: "Edit mission",
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isSaving ? null : _showAddSubMissionDialog,
        backgroundColor: const Color(AppColors.primary),
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.add, color: Colors.white),
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
                    subtitle: submission.description.trim().isNotEmpty
                        ? Text(
                            submission.description,
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

  Future<void> _toggleTaskDone(TaskItem task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index == -1) return;

    final updated = task.copyWith(
      done: !task.done,
      completedAt: !task.done ? DateTime.now() : null,
    );

    setState(() {
      _tasks[index] = updated;
    });
    await _saveTasks();
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
        backgroundColor: const Color(AppColors.background),
        iconTheme: const IconThemeData(color: Color(AppColors.textMain)),
        title: Text(
          widget.subMissionTitle,
          style: const TextStyle(
            color: Color(AppColors.textMain),
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
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
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => TaskDetailsPage(
                                    task: task,
                                    onDelete: () {
                                      setState(() {
                                        _tasks.remove(task);
                                      });
                                      _saveTasks();
                                    },
                                    onUpdate: (updated) {
                                      final index = _tasks.indexWhere(
                                        (t) => t.id == updated.id,
                                      );
                                      if (index == -1) return;
                                      setState(() {
                                        _tasks[index] = updated;
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
                              onToggleDone: () => _toggleTaskDone(task),
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
