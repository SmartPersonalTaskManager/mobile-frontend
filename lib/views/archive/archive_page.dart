import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sptm/models/task_item.dart';
import 'package:sptm/services/task_service.dart';
import 'package:sptm/core/constants.dart';

import 'package:flutter/material.dart';

class ArchivePage extends StatefulWidget {
  const ArchivePage({super.key});

  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  List<TaskItem> _tasks = [];
  bool _isLoading = true;
  final TaskService _taskService = TaskService();

  @override
  void initState() {
    super.initState();
    _loadArchivedTasks();
  }

  Future<void> _loadArchivedTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      return;
    }

    try {
      final allTasks = await _taskService.getTasks(userId);
      if (!mounted) return;
      setState(() {
        _tasks = allTasks.where((t) => t.isArchived).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading archived tasks: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(AppColors.background),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      appBar: AppBar(
        backgroundColor: const Color(AppColors.background),
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        title: const Text(
          "Archive",
          style: TextStyle(
            color: Color(AppColors.textMain),
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: const [
          _IconCircle(icon: Icons.light_mode_outlined),
          SizedBox(width: 12),
          _IconCircle(icon: Icons.search),
          SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _loadArchivedTasks,
          color: Colors.deepPurple,
          backgroundColor: Colors.white,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      const Text(
                        "Review your accomplishments",
                        style: TextStyle(color: Color(AppColors.textMuted)),
                      ),
                      const SizedBox(height: 16),
                      _TopControls(completedCount: _tasks.length),
                      const SizedBox(height: 16),
                      const _QuadrantFilters(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              if (_tasks.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      "No archived tasks",
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final task = _tasks[index];
                      return _TaskCard(
                        task,
                        onUnarchive: () async {
                          await _taskService.updateTask(
                            task.copyWith(isArchived: false),
                          );
                          _loadArchivedTasks();
                        },
                        onDelete: () async {
                          await _taskService.deleteTask(task.id);
                          _loadArchivedTasks();
                        },
                      );
                    }, childCount: _tasks.length),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopControls extends StatelessWidget {
  final int completedCount;
  const _TopControls({required this.completedCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: const [
              Icon(Icons.sort, color: Colors.deepPurple),
              SizedBox(width: 8),
              Text(
                "Sort by: Done Date",
                style: TextStyle(color: Colors.white70),
              ),
              Icon(Icons.keyboard_arrow_down, color: Colors.white54),
            ],
          ),
        ),
        const Spacer(),
        Text(
          "$completedCount Tasks Completed",
          style: const TextStyle(color: Colors.white54),
        ),
      ],
    );
  }
}

class _IconCircle extends StatelessWidget {
  final IconData icon;
  const _IconCircle({required this.icon});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: const Color(AppColors.surface),
      child: Icon(icon, color: const Color(AppColors.textMain)),
    );
  }
}

class _QuadrantFilters extends StatelessWidget {
  const _QuadrantFilters();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: const [
          _FilterChip(label: "All", selected: true),
          _FilterChip(label: "Q1: Urgent & Important"),
          _FilterChip(label: "Q2: Not Urgent & Important"),
          _FilterChip(label: "Q3: Urgent & Not Important"),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;

  const _FilterChip({required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        backgroundColor: selected ? Colors.deepPurple : const Color(0xFF161B22),
        label: Text(
          label,
          style: TextStyle(color: selected ? Colors.white : Colors.white70),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white54,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskItem task;
  final VoidCallback onUnarchive;
  final VoidCallback onDelete;

  const _TaskCard(
    this.task, {
    required this.onUnarchive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(AppColors.surface),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            InkWell(
              onTap: onUnarchive,
              child: const Icon(Icons.restore, color: Colors.deepPurple),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      color: Colors.white,
                      decoration: TextDecoration.lineThrough,
                      fontSize: 16,
                    ),
                  ),
                  if (task.description != null &&
                      task.description!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      task.description!,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white24, size: 20),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
