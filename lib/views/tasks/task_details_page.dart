import 'package:flutter/material.dart';
import 'package:sptm/core/constants.dart';
import 'package:sptm/models/task_item.dart';
import 'package:sptm/services/task_service.dart';

class TaskDetailsPage extends StatefulWidget {
  final TaskItem task;
  final VoidCallback? onDelete;
  final VoidCallback? onArchive;
  final ValueChanged<TaskItem>? onUpdate;

  const TaskDetailsPage({
    super.key,
    required this.task,
    this.onDelete,
    this.onArchive,
    this.onUpdate,
  });

  @override
  State<TaskDetailsPage> createState() => _TaskDetailsPageState();
}

class _ChecklistItem {
  final TextEditingController controller;
  final FocusNode focusNode;
  bool done;

  _ChecklistItem({String title = "", this.done = false})
    : controller = TextEditingController(text: title),
      focusNode = FocusNode();

  void dispose() {
    controller.dispose();
    focusNode.dispose();
  }
}

class _TaskDetailsPageState extends State<TaskDetailsPage> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contextController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  final List<_ChecklistItem> _checklist = [];
  final TaskService _taskService = TaskService();
  late TaskItem _task;
  DateTime? _dueDate;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _titleController.text = _task.title;
    _descriptionController.text = _task.description ?? '';
    _contextController.text = _task.context ?? '';
    _dueDate = _task.dueDate;
    _dueDateController.text = _dueDate != null ? _formatDate(_dueDate!) : '';
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _titleController.dispose();
    _contextController.dispose();
    _dueDateController.dispose();
    for (final item in _checklist) {
      item.dispose();
    }
    super.dispose();
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

  void _addChecklistItem() {
    final item = _ChecklistItem();
    setState(() {
      _checklist.add(item);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      item.focusNode.requestFocus();
    });
  }

  void _finalizeChecklistItem(_ChecklistItem item) {
    final value = item.controller.text.trim();
    if (value.isEmpty) {
      setState(() {
        _checklist.remove(item);
        item.dispose();
      });
      return;
    }
    item.controller.text = value;
  }

  Future<void> _confirmDeleteTask() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(AppColors.surface),
          title: const Text(
            "Delete Task",
            style: TextStyle(color: Color(AppColors.textMain)),
          ),
          content: const Text(
            "Are you sure you want to delete this task?",
            style: TextStyle(color: Color(AppColors.textMuted)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      widget.onDelete?.call();
      Navigator.pop(context);
    }
  }

  void _archiveTask() {
    widget.onArchive?.call();
    Navigator.pop(context);
  }

  Future<void> _toggleComplete() async {
    // Toggle logic
    final newStatus = !_task.done;
    final updated = _task.copyWith(done: newStatus);
    // Note: copyWith(done:...) doesn't exist in backend DTO logic directly,
    // but TaskItem.toJson handles 'done' -> 'status'.
    // We need to ensure we set the status correctly if we rely on toJson.
    // Actually TaskItem logic: 'status': done ? "COMPLETED" : "NOT_STARTED"
    // So updating 'done' is sufficient for toJson to send correct status.

    setState(() => _isSaving = true);
    try {
      final saved = await _taskService.updateTask(updated);
      if (!mounted) return;
      setState(() {
        _task = saved;
        _isSaving = false;
      });
      widget.onUpdate?.call(saved);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
    }
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() {
      _dueDate = picked;
      _dueDateController.text = _formatDate(picked);
    });
  }

  Future<void> _saveEdits() async {
    if (_isSaving) return;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Task title is required.')));
      return;
    }

    final updated = _task.copyWith(
      title: title,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      context: _contextController.text.trim().isEmpty
          ? null
          : _contextController.text.trim(),
      dueDate: _dueDate,
    );

    setState(() => _isSaving = true);
    try {
      final saved = await _taskService.updateTask(updated);
      if (!mounted) return;
      setState(() {
        _task = saved;
        _titleController.text = saved.title;
        _descriptionController.text = saved.description ?? '';
        _contextController.text = saved.context ?? '';
        _dueDate = saved.dueDate;
        _dueDateController.text = saved.dueDate != null
            ? _formatDate(saved.dueDate!)
            : '';
        _isEditing = false;
        _isSaving = false;
      });
      widget.onUpdate?.call(saved);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update task: $e')));
    }
  }

  Widget _actionIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(AppColors.surface),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  blurRadius: 8,
                  color: Colors.black.withOpacity(0.2),
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      appBar: AppBar(
        backgroundColor: const Color(AppColors.background),
        iconTheme: const IconThemeData(color: Color(AppColors.textMain)),
        title: _isEditing
            ? TextField(
                controller: _titleController,
                autofocus: true,
                textInputAction: TextInputAction.done,
                style: const TextStyle(
                  color: Color(AppColors.textMain),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  hintText: 'Task title',
                  hintStyle: TextStyle(color: Color(AppColors.textMuted)),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _saveEdits(),
              )
            : Text(
                _task.title,
                style: const TextStyle(
                  color: Color(AppColors.textMain),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
        actions: [
          _actionIconButton(
            icon: _isEditing ? Icons.check : Icons.edit,
            onTap: _isEditing
                ? _saveEdits
                : () => setState(() => _isEditing = true),
            iconColor: const Color(AppColors.textMain),
          ),
          _actionIconButton(
            icon: _task.done ? Icons.undo : Icons.check_circle_outline,
            onTap: _toggleComplete,
            iconColor: _task.done
                ? const Color(AppColors.textMuted)
                : const Color(AppColors.success),
          ),
          _actionIconButton(
            icon: Icons.archive_outlined,
            onTap: _archiveTask,
            iconColor: const Color(AppColors.primary),
          ),
          _actionIconButton(
            icon: Icons.delete_outline,
            onTap: _confirmDeleteTask,
            iconColor: const Color(AppColors.danger),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(AppColors.surface),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Linked Submission",
                        style: TextStyle(
                          color: Color(AppColors.textMuted),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_isEditing) ...[
                        TextField(
                          controller: _dueDateController,
                          readOnly: true,
                          onTap: _pickDueDate,
                          style: const TextStyle(
                            color: Color(AppColors.textMain),
                          ),
                          decoration: InputDecoration(
                            hintText: "Due date",
                            hintStyle: const TextStyle(
                              color: Color(AppColors.textMuted),
                            ),
                            filled: true,
                            fillColor: const Color(AppColors.surfaceBase),
                            suffixIcon: _dueDate != null
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Color(AppColors.textMuted),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _dueDate = null;
                                        _dueDateController.clear();
                                      });
                                    },
                                  )
                                : const Icon(
                                    Icons.calendar_today,
                                    color: Color(AppColors.textMuted),
                                  ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _contextController,
                          textInputAction: TextInputAction.done,
                          style: const TextStyle(
                            color: Color(AppColors.textMain),
                          ),
                          decoration: InputDecoration(
                            hintText: "Context",
                            hintStyle: const TextStyle(
                              color: Color(AppColors.textMuted),
                            ),
                            filled: true,
                            fillColor: const Color(AppColors.surfaceBase),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ] else ...[
                        Text(
                          _task.mission ?? "No Mission",
                          style: const TextStyle(
                            color: Color(AppColors.textMain),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "${_task.dueDate != null ? "Due ${_formatDate(_task.dueDate!)}" : "No due date"} · ${_task.context ?? "No context"}",
                          style: const TextStyle(
                            color: Color(AppColors.textMuted),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Description",
                  style: TextStyle(
                    color: Color(AppColors.textMain),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  readOnly: !_isEditing,
                  style: const TextStyle(color: Color(AppColors.textMain)),
                  decoration: InputDecoration(
                    hintText: "Add details or notes for this task",
                    hintStyle: const TextStyle(
                      color: Color(AppColors.textMuted),
                    ),
                    filled: true,
                    fillColor: const Color(AppColors.surface),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Checklist",
                  style: TextStyle(
                    color: Color(AppColors.textMain),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ..._checklist.map((item) {
                  final done = item.done;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(AppColors.surface),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: done,
                          activeColor: const Color(AppColors.primary),
                          onChanged: (value) {
                            setState(() {
                              item.done = value ?? false;
                            });
                          },
                        ),
                        Expanded(
                          child:
                              item.controller.text.isEmpty ||
                                  item.focusNode.hasFocus
                              ? Focus(
                                  onFocusChange: (hasFocus) {
                                    if (!hasFocus) {
                                      _finalizeChecklistItem(item);
                                    }
                                  },
                                  child: TextField(
                                    controller: item.controller,
                                    focusNode: item.focusNode,
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) =>
                                        _finalizeChecklistItem(item),
                                    style: const TextStyle(
                                      color: Color(AppColors.textMain),
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: "Checklist item",
                                      hintStyle: TextStyle(
                                        color: Color(AppColors.textMuted),
                                      ),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                )
                              : Text(
                                  item.controller.text,
                                  style: TextStyle(
                                    color: const Color(AppColors.textMain),
                                    decoration: done
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  );
                }),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: _addChecklistItem,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(AppColors.surface),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.add_circle, color: Color(AppColors.primary)),
                        SizedBox(width: 10),
                        Text(
                          "Add a checklist item",
                          style: TextStyle(color: Color(AppColors.textMuted)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
