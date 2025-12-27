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
  List<TaskItem> _allTasks = []; // Store all fetched tasks
  List<TaskItem> _filteredTasks = []; // Store currently displayed tasks

  String _selectedFilter = "All";
  String _selectedSort = "Done Date";

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

      final archived = allTasks.where((t) => t.isArchived).toList();

      setState(() {
        _allTasks = archived;
        _isLoading = false;
        _applyFilterAndSort();
      });
    } catch (e) {
      debugPrint("Error loading archived tasks: $e");
      setState(() => _isLoading = false);
    }
  }

  void _applyFilterAndSort() {
    List<TaskItem> temp = List.from(_allTasks);

    // Filter
    if (_selectedFilter != "All") {
      temp = temp.where((t) {
        if (_selectedFilter == "Q1: Urgent & Important") {
          return t.urgent && t.important;
        } else if (_selectedFilter == "Q2: Not Urgent & Important") {
          return !t.urgent && t.important;
        } else if (_selectedFilter == "Q3: Urgent & Not Important") {
          return t.urgent && !t.important;
        } else if (_selectedFilter == "Q4: Not Urgent & Not Important") {
          return !t.urgent && !t.important;
        }
        return true;
      }).toList();
    }

    // Sort
    temp.sort((a, b) {
      if (_selectedSort == "Done Date") {
        // Fallback to ID if completedAt is null, or sort by ID descending if both null
        final dateA = a.completedAt ?? DateTime(2000);
        final dateB = b.completedAt ?? DateTime(2000);
        return dateB.compareTo(dateA);
      } else if (_selectedSort == "Created Date") {
        return b.id.compareTo(
          a.id,
        ); // Assuming ID correlates with creation time
      } else if (_selectedSort == "Title") {
        return a.title.compareTo(b.title);
      }
      return 0;
    });

    setState(() {
      _filteredTasks = temp;
    });
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(AppColors.surface),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text(
                "Sort by",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _SortOption(
                label: "Done Date",
                selected: _selectedSort == "Done Date",
                onTap: () {
                  setState(() => _selectedSort = "Done Date");
                  _applyFilterAndSort();
                  Navigator.pop(context);
                },
              ),
              _SortOption(
                label: "Created Date",
                selected: _selectedSort == "Created Date",
                onTap: () {
                  setState(() => _selectedSort = "Created Date");
                  _applyFilterAndSort();
                  Navigator.pop(context);
                },
              ),
              _SortOption(
                label: "Title",
                selected: _selectedSort == "Title",
                onTap: () {
                  setState(() => _selectedSort = "Title");
                  _applyFilterAndSort();
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
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
          color: const Color(AppColors.primary),
          backgroundColor: const Color(AppColors.background),
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
                      _TopControls(
                        completedCount: _allTasks.length,
                        currentSort: _selectedSort,
                        onSortTap: _showSortOptions,
                      ),
                      const SizedBox(height: 16),
                      _QuadrantFilters(
                        selectedFilter: _selectedFilter,
                        onFilterSelected: (filter) {
                          setState(() => _selectedFilter = filter);
                          _applyFilterAndSort();
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              if (_filteredTasks.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      "No archived tasks found",
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final task = _filteredTasks[index];
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
                    }, childCount: _filteredTasks.length),
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
  final String currentSort;
  final VoidCallback onSortTap;

  const _TopControls({
    required this.completedCount,
    required this.currentSort,
    required this.onSortTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onSortTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.sort, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(
                  "Sort by: $currentSort",
                  style: const TextStyle(color: Colors.white70),
                ),
                const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
              ],
            ),
          ),
        ),
        const Spacer(),
        Text(
          "$completedCount Tasks Total", // Changed to Total since we might filter
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
  final String selectedFilter;
  final Function(String) onFilterSelected;

  const _QuadrantFilters({
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: "All",
            selected: selectedFilter == "All",
            onTap: () => onFilterSelected("All"),
          ),
          _FilterChip(
            label: "Q1: Urgent & Important",
            selected: selectedFilter == "Q1: Urgent & Important",
            onTap: () => onFilterSelected("Q1: Urgent & Important"),
          ),
          _FilterChip(
            label: "Q2: Not Urgent & Important",
            selected: selectedFilter == "Q2: Not Urgent & Important",
            onTap: () => onFilterSelected("Q2: Not Urgent & Important"),
          ),
          _FilterChip(
            label: "Q3: Urgent & Not Important",
            selected: selectedFilter == "Q3: Urgent & Not Important",
            onTap: () => onFilterSelected("Q3: Urgent & Not Important"),
          ),
          _FilterChip(
            label: "Q4: Not Urgent & Not Important",
            selected: selectedFilter == "Q4: Not Urgent & Not Important",
            onTap: () => onFilterSelected("Q4: Not Urgent & Not Important"),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Chip(
          backgroundColor: selected
              ? Colors.deepPurple
              : const Color(0xFF161B22),
          label: Text(
            label,
            style: TextStyle(color: selected ? Colors.white : Colors.white70),
          ),
        ),
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SortOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? Colors.deepPurple : Colors.white54,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.deepPurple : Colors.white70,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
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
