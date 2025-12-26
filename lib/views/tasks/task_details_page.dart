import 'package:flutter/material.dart';
import 'package:sptm/core/constants.dart';

class TaskDetailsPage extends StatefulWidget {
  final String title;
  final String submission;
  final DateTime? dueDate;
  final String? context;
  final VoidCallback? onDelete;
  final VoidCallback? onArchive;

  const TaskDetailsPage({
    super.key,
    required this.title,
    required this.submission,
    this.dueDate,
    this.context,
    this.onDelete,
    this.onArchive,
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
  final List<_ChecklistItem> _checklist = [];

  @override
  void dispose() {
    _descriptionController.dispose();
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
        backgroundColor: const Color(AppColors.surface),
        iconTheme: const IconThemeData(color: Color(AppColors.textMain)),
        title: Text(
          widget.title,
          style: const TextStyle(color: Color(AppColors.textMain)),
        ),
        actions: [
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
                      Text(
                        widget.submission,
                        style: const TextStyle(
                          color: Color(AppColors.textMain),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "${widget.dueDate != null ? "Due ${_formatDate(widget.dueDate!)}" : "No due date"} · ${widget.context ?? "No context"}",
                        style: const TextStyle(
                          color: Color(AppColors.textMuted),
                        ),
                      ),
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
