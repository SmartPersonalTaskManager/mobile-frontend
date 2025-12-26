import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sptm/core/constants.dart';
import 'package:sptm/models/task_item.dart';
import 'package:sptm/services/task_service.dart';
import 'package:sptm/views/dashboard/widgets/task_card.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  final Color _background = const Color(AppColors.background);
  final Color _card = const Color(AppColors.surface);
  final Color _accent = const Color(AppColors.primary);
  final Color _muted = const Color(AppColors.textMuted);

  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDay;
  final List<TaskItem> _tasks = [];
  final TaskService _taskService = TaskService();

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int _daysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  int _leadingEmptySlots(DateTime date) {
    final firstWeekday = DateTime(date.year, date.month, 1).weekday;
    return firstWeekday - 1;
  }

  Future<void> _loadTasks() async {
    final selectedDay = _selectedDay;
    if (selectedDay == null) {
      if (!mounted) return;
      setState(() {
        _tasks.clear();
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("userId");
    if (userId == null) return;

    try {
      final tasks = await _taskService.getTasksForDay(
        userId: userId,
        day: selectedDay,
      );
      if (!mounted) return;
      setState(() {
        _tasks
          ..clear()
          ..addAll(tasks.where((task) => !task.isArchived));
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to load tasks: $e")));
    }
  }

  Future<void> _toggleTaskDone(TaskItem task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index == -1) return;

    final optimistic = task.copyWith(
      done: !task.done,
      completedAt: !task.done ? DateTime.now() : null,
    );

    setState(() {
      _tasks[index] = optimistic;
    });

    try {
      final saved = await _taskService.toggleTaskDone(task);
      if (!mounted) return;
      setState(() {
        _tasks[index] = saved;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _tasks[index] = task;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to update task: $e")));
    }
  }

  List<TaskItem> _tasksForSelectedDay() {
    final selectedDay = _selectedDay;
    if (selectedDay == null) return [];
    return _tasks;
  }

  String _urgencyLabel(TaskItem task) {
    final urgency = task.urgent ? "Urgent" : "Not urgent";
    final importance = task.important ? "Important" : "Not important";
    return "$urgency · $importance";
  }

  Future<void> _selectDay(DateTime date) async {
    setState(() {
      _selectedDay = date;
    });
    await _loadTasks();
  }

  void _goToPreviousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  Widget _buildHeader() {
    final monthLabel =
        '${_monthNames[_focusedMonth.month - 1]} ${_focusedMonth.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: _goToPreviousMonth,
              icon: const Icon(Icons.chevron_left),
              color: const Color(AppColors.textMain),
              splashRadius: 20,
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  monthLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(AppColors.textMain),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: _goToNextMonth,
              icon: const Icon(Icons.chevron_right),
              color: const Color(AppColors.textMain),
              splashRadius: 20,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeekdayLabels() {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(
      children: labels
          .map(
            (label) => Expanded(
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(color: _muted, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final totalDays = _daysInMonth(_focusedMonth);
    final leadingSlots = _leadingEmptySlots(_focusedMonth);
    final totalSlots = (leadingSlots + totalDays) % 7 == 0
        ? leadingSlots + totalDays
        : null;
    final slots =
        totalSlots ??
        (leadingSlots + totalDays + (7 - (leadingSlots + totalDays) % 7));

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: slots,
      itemBuilder: (context, index) {
        if (index < leadingSlots || index >= leadingSlots + totalDays) {
          return const SizedBox.shrink();
        }

        final dayNumber = index - leadingSlots + 1;
        final date = DateTime(
          _focusedMonth.year,
          _focusedMonth.month,
          dayNumber,
        );
        final isToday = _isSameDay(date, DateTime.now());
        final isSelected =
            _selectedDay != null && _isSameDay(date, _selectedDay!);

        return GestureDetector(
          onTap: () {
            _selectDay(date);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected ? _accent : _card,
              borderRadius: BorderRadius.circular(10),
              border: isToday
                  ? Border.all(color: _accent, width: 2)
                  : Border.all(color: Colors.transparent, width: 2),
            ),
            child: Center(
              child: Text(
                '$dayNumber',
                style: TextStyle(
                  color: isSelected
                      ? const Color(AppColors.textInverted)
                      : const Color(AppColors.textMain),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dueTasks = _tasksForSelectedDay();

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: const Color(AppColors.background),
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        title: const Text(
          'Calendar',
          style: TextStyle(
            color: Color(AppColors.textMain),
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: _accent,
          backgroundColor: _background,
          onRefresh: _loadTasks,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                _buildWeekdayLabels(),
                const SizedBox(height: 12),
                _buildCalendarGrid(),
                const SizedBox(height: 24),

                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            "Tasks due",
                            style: TextStyle(
                              color: Color(AppColors.textMain),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _selectedDay == null
                                ? "-"
                                : dueTasks.length.toString(),
                            style: const TextStyle(
                              color: Color(AppColors.textMuted),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_selectedDay == null)
                        const Text(
                          "Select a date to see tasks due that day.",
                          style: TextStyle(color: Color(AppColors.textMuted)),
                        )
                      else if (dueTasks.isEmpty)
                        const Text(
                          "No tasks due on this date.",
                          style: TextStyle(color: Color(AppColors.textMuted)),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: dueTasks.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final task = dueTasks[index];
                            return TaskCard(
                              title: task.title,
                              subtitle:
                                  "${task.mission} · ${task.context} · ${_urgencyLabel(task)}",
                              done: task.done,
                              onToggleDone: () => _toggleTaskDone(task),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
