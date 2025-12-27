import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sptm/core/constants.dart';
import 'package:sptm/models/context_tag.dart';
import 'package:sptm/models/mission.dart';
import 'package:sptm/models/task_item.dart';
import 'package:sptm/services/context_service.dart';
import 'package:sptm/services/mission_service.dart';
import 'package:sptm/services/notification_service.dart';
import 'package:sptm/services/task_service.dart';

// TODO if there are quick-add tasks not assigned, show a notification about that

import '../../models/notification_item.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  final Color bg = const Color(AppColors.background);
  final Color cardColor = const Color(AppColors.surface);
  final Color green = const Color(AppColors.primary);
  late TabController tabController;
  late NotificationService service;
  final TaskService _taskService = TaskService();
  final ContextService _contextService = ContextService();
  final MissionService _missionService = MissionService();
  List<NotificationItem> items = [];
  List<TaskItem> inboxTasks = [];
  final List<ContextTag> _contexts = [];
  final List<SubMission> _subMissions = [];

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 4, vsync: this);
    service = NotificationService();
    _loadData();
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(AppColors.background),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(AppColors.textMain)),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        "Notifications",
        style: TextStyle(
          color: Color(AppColors.textMain),
          fontWeight: FontWeight.bold,
          fontSize: 28,
        ),
      ),
      actions: [
        TextButton(
          onPressed: _markAllRead,
          child: const Text(
            "Mark all read",
            style: TextStyle(color: Color(AppColors.primary)),
          ),
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  Future<void> _loadData() async {
    items = await service.loadNotifications();
    await _loadInboxTasks();
    setState(() {});
  }

  Future<void> _loadInboxTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("userId");
    if (userId == null) {
      inboxTasks = [];
      return;
    }

    try {
      final tasks = await _taskService.getTasks(userId);
      inboxTasks = tasks
          .where((task) => task.isInbox && !task.isArchived)
          .toList()
        ..sort((a, b) => b.id.compareTo(a.id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load inbox tasks: $e")),
      );
    }
  }

  Future<void> _loadContexts() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("userId");
    if (userId == null) return;

    try {
      final contexts = await _contextService.fetchUserContexts(userId);
      _contexts
        ..clear()
        ..addAll(contexts);
    } catch (_) {
      // ignore failures here; handled in the sheet if needed
    }
  }

  Future<void> _loadSubMissions() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("userId");
    if (userId == null) return;

    try {
      final missions = await _missionService.fetchUserMissions(userId);
      final loaded = <SubMission>[];
      for (final Mission mission in missions) {
        for (final SubMission subMission in mission.subMissions) {
          if (subMission.title.trim().isNotEmpty) {
            loaded.add(subMission);
          }
        }
      }
      _subMissions
        ..clear()
        ..addAll(loaded..sort((a, b) => a.title.compareTo(b.title)));
    } catch (_) {
      // ignore failures here; handled in the sheet if needed
    }
  }

  bool get _hasSubMissions => _subMissions.isNotEmpty;

  List<DropdownMenuItem<int>> _buildSubMissionItems() {
    if (_subMissions.isEmpty) {
      return const [
        DropdownMenuItem<int>(
          value: -1,
          child: Text("No sub-missions available"),
        ),
      ];
    }
    return _subMissions
        .map(
          (subMission) => DropdownMenuItem<int>(
            value: subMission.id,
            child: Text(subMission.title),
          ),
        )
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

  Future<void> _openQuickTaskAssignmentSheet(TaskItem task) async {
    await _loadSubMissions();
    await _loadContexts();
    final titleController = TextEditingController(text: task.title);
    final dueDateController = TextEditingController(
      text: task.dueDate == null ? "" : _formatDate(task.dueDate!),
    );
    bool? urgent = task.urgent;
    bool? important = task.important;
    int? selectedSubMissionId = task.subMissionId;
    String? selectedContext = task.context;
    DateTime? dueDate = task.dueDate;
    String? errorText;

    Future<void> selectDueDate(StateSetter setModalState) async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: dueDate ?? now,
        firstDate: now.subtract(const Duration(days: 1)),
        lastDate: DateTime(now.year + 5),
      );
      if (picked == null) return;
      dueDate = picked;
      dueDateController.text = _formatDate(picked);
      setModalState(() {
        errorText = null;
      });
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(AppColors.surface),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (errorText != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(AppColors.surfaceBase),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(AppColors.danger).withOpacity(0.6),
                        ),
                      ),
                      child: Text(
                        errorText!,
                        style: const TextStyle(
                          color: Color(AppColors.textMain),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: errorText == null ? 16 : 0,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            "Create Full Task",
                            style: TextStyle(
                              color: Color(AppColors.textMain),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Color(AppColors.textMuted),
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<bool>(
                        value: urgent,
                        hint: const Text(
                          "Task urgency",
                          style: TextStyle(color: Color(AppColors.textMuted)),
                        ),
                        dropdownColor: const Color(AppColors.surface),
                        iconEnabledColor: const Color(AppColors.textMuted),
                        style: const TextStyle(
                          color: Color(AppColors.textMain),
                        ),
                        items: const [
                          DropdownMenuItem(value: true, child: Text("Urgent")),
                          DropdownMenuItem(
                            value: false,
                            child: Text("Not urgent"),
                          ),
                        ],
                        onChanged: (value) {
                          setModalState(() {
                            urgent = value;
                            errorText = null;
                          });
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(AppColors.surfaceBase),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<bool>(
                        value: important,
                        hint: const Text(
                          "Task importance",
                          style: TextStyle(color: Color(AppColors.textMuted)),
                        ),
                        dropdownColor: const Color(AppColors.surface),
                        iconEnabledColor: const Color(AppColors.textMuted),
                        style: const TextStyle(
                          color: Color(AppColors.textMain),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: true,
                            child: Text("Important"),
                          ),
                          DropdownMenuItem(
                            value: false,
                            child: Text("Not important"),
                          ),
                        ],
                        onChanged: (value) {
                          setModalState(() {
                            important = value;
                            errorText = null;
                          });
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(AppColors.surfaceBase),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: titleController,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) {
                          setModalState(() {
                            errorText = null;
                          });
                        },
                        style: const TextStyle(
                          color: Color(AppColors.textMain),
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: "Task title",
                          hintStyle: const TextStyle(
                            color: Color(AppColors.textMuted),
                          ),
                          filled: true,
                          fillColor: const Color(AppColors.surfaceBase),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: selectedSubMissionId,
                        hint: Text(
                          _hasSubMissions
                              ? "Linked sub-mission"
                              : "No sub-missions available",
                          style: const TextStyle(
                            color: Color(AppColors.textMuted),
                          ),
                        ),
                        dropdownColor: const Color(AppColors.surface),
                        iconEnabledColor: const Color(AppColors.textMuted),
                        style: const TextStyle(
                          color: Color(AppColors.textMain),
                        ),
                        items: _buildSubMissionItems(),
                        onChanged: _hasSubMissions
                            ? (value) {
                                setModalState(() {
                                  selectedSubMissionId =
                                      value == null || value == -1
                                          ? null
                                          : value;
                                  errorText = null;
                                });
                              }
                            : null,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(AppColors.surfaceBase),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedContext,
                        hint: const Text(
                          "Context",
                          style: TextStyle(color: Color(AppColors.textMuted)),
                        ),
                        dropdownColor: const Color(AppColors.surface),
                        iconEnabledColor: const Color(AppColors.textMuted),
                        style: const TextStyle(
                          color: Color(AppColors.textMain),
                        ),
                        items: [
                          ..._contexts.map(
                            (contextTag) => DropdownMenuItem(
                              value: contextTag.name,
                              child: Text(contextTag.name),
                            ),
                          ),
                          const DropdownMenuItem(
                            value: "__add__",
                            child: Text("Add new context..."),
                          ),
                        ],
                        onChanged: (value) async {
                          if (value == "__add__") {
                            final controller = TextEditingController();
                            final result = await showDialog<String>(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  backgroundColor: const Color(
                                    AppColors.surface,
                                  ),
                                  title: const Text(
                                    "Add Context",
                                    style: TextStyle(
                                      color: Color(AppColors.textMain),
                                    ),
                                  ),
                                  content: TextField(
                                    controller: controller,
                                    autofocus: true,
                                    textInputAction: TextInputAction.done,
                                    style: const TextStyle(
                                      color: Color(AppColors.textMain),
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: "e.g. @errands",
                                      hintStyle: TextStyle(
                                        color: Color(AppColors.textMuted),
                                      ),
                                    ),
                                    onSubmitted: (_) {
                                      Navigator.of(
                                        context,
                                      ).pop(controller.text);
                                    },
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: const Text("Cancel"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.of(
                                        context,
                                      ).pop(controller.text),
                                      child: const Text("Add"),
                                    ),
                                  ],
                                );
                              },
                            );
                            final rawContext = result?.trim();
                            if (rawContext == null || rawContext.isEmpty) {
                              return;
                            }
                            final newContext = rawContext.startsWith("@")
                                ? rawContext
                                : "@$rawContext";
                            final alreadyExists = _contexts.any(
                              (contextTag) => contextTag.name == newContext,
                            );
                            if (!alreadyExists) {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              final userId = prefs.getInt("userId");
                              if (userId == null) {
                                if (!mounted) return;
                                setModalState(() {
                                  errorText =
                                      "Missing user info for context creation.";
                                });
                                return;
                              }
                              try {
                                final created = await _contextService
                                    .createContext(
                                      userId: userId,
                                      name: newContext,
                                    );
                                _contexts.add(created);
                              } catch (e) {
                                if (!mounted) return;
                                setModalState(() {
                                  errorText = "Failed to create context: $e";
                                });
                                return;
                              }
                            }
                            setModalState(() {
                              selectedContext = newContext;
                              errorText = null;
                            });
                          } else {
                            setModalState(() {
                              selectedContext = value;
                              errorText = null;
                            });
                          }
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(AppColors.surfaceBase),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: dueDateController,
                        readOnly: true,
                        onTap: () => selectDueDate(setModalState),
                        style: const TextStyle(
                          color: Color(AppColors.textMain),
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: "Due date",
                          hintStyle: const TextStyle(
                            color: Color(AppColors.textMuted),
                          ),
                          suffixIcon: const Icon(
                            Icons.calendar_today,
                            color: Color(AppColors.textMuted),
                            size: 18,
                          ),
                          filled: true,
                          fillColor: const Color(AppColors.surfaceBase),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(AppColors.primary),
                            foregroundColor: const Color(
                              AppColors.textInverted,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            final title = titleController.text.trim();
                            if (urgent == null ||
                                important == null ||
                                title.isEmpty ||
                                selectedContext == null ||
                                dueDate == null) {
                              setModalState(() {
                                errorText =
                                    "Please complete all task fields before saving.";
                              });
                              return;
                            }
                            if (_hasSubMissions &&
                                selectedSubMissionId == null) {
                              setModalState(() {
                                errorText = "Please select a sub-mission.";
                              });
                              return;
                            }

                            try {
                              final updated = task.copyWith(
                                title: title,
                                urgent: urgent ?? false,
                                important: important ?? false,
                                context: selectedContext,
                                dueDate: dueDate,
                                subMissionId: selectedSubMissionId,
                                isInbox: false,
                              );
                              await _taskService.updateTask(updated);
                              if (!mounted) return;
                              await _loadInboxTasks();
                              setState(() {});
                              Navigator.pop(context);
                            } catch (e) {
                              setModalState(() {
                                errorText = "Failed to update task: $e";
                              });
                            }
                          },
                          child: const Text("Save Task"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _markAllRead() async {
    await service.markAllRead();
    await _loadData();
  }

  Future<void> _markItemRead(String id) async {
    await service.markRead(id);
    await _loadData();
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(AppColors.surface),
          borderRadius: BorderRadius.circular(14),
        ),
        child: TabBar(
          controller: tabController,
          labelColor: const Color(AppColors.textMain),
          unselectedLabelColor: const Color(AppColors.textMuted),
          indicator: BoxDecoration(
            color: green.withOpacity(0.2),
            borderRadius: BorderRadius.circular(14),
          ),
          tabs: const [
            Tab(text: "All"),
            Tab(text: "Inbox"),
            Tab(text: "Reviews"),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(AppColors.textMuted),
          letterSpacing: 1,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildNotificationCardNew({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String time,
    Widget? actionButton,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIcon(icon, iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Color(AppColors.textMain),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(
                        color: Color(AppColors.success),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(AppColors.textMuted),
                    height: 1.4,
                    fontSize: 14,
                  ),
                ),
                if (actionButton != null) ...[
                  const SizedBox(height: 14),
                  actionButton,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(IconData icon, Color color) {
    return Stack(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        Positioned(
          left: 2,
          bottom: 0,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(AppColors.primary),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmallActionButton(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: green.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(AppColors.primary),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSwipeNotification({
    Key? key,
    required String title,
    required String message,
    required String time,
    IconData icon = Icons.check,
    Color iconColor = const Color(AppColors.textMuted),
    bool done = false,
    VoidCallback? onTap,
    DismissDirection dismissDirection = DismissDirection.horizontal,
    DismissDirectionCallback? onDismissed,
  }) {
    return Dismissible(
      key: key ?? UniqueKey(),
      direction: dismissDirection,
      onDismissed: onDismissed,
      background: _buildSwipeBackground(),
      secondaryBackground: _buildSwipeDelete(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _buildIcon(icon, iconColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Opacity(
                    opacity: done ? 0.5 : 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  color: const Color(AppColors.textMain),
                                  fontSize: 15,
                                  decoration: done
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                            Text(
                              time,
                              style: const TextStyle(
                                color: Color(AppColors.textMuted),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          message,
                          style: const TextStyle(
                            color: Color(AppColors.textMuted),
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeBackground() {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 20),
      color: const Color(AppColors.surfaceBase),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.archive, color: Color(AppColors.textMain)),
          SizedBox(height: 4),
          Text("Archive", style: TextStyle(color: Color(AppColors.textMain))),
        ],
      ),
    );
  }

  Widget _buildSwipeDelete() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      color: const Color(AppColors.danger),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete, color: Color(AppColors.textMain)),
          SizedBox(height: 4),
          Text("Delete", style: TextStyle(color: Color(AppColors.textMain))),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    final unreadItems = items.where((item) => !item.read).toList();
    if (unreadItems.isEmpty) {
      return const Center(
        child: Text(
          "No notifications yet.",
          style: TextStyle(color: Color(AppColors.textMuted)),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: unreadItems.length,
        itemBuilder: (context, index) {
          final item = unreadItems[index];
          return _buildSwipeNotification(
            key: ValueKey("notification_${item.id}"),
            title: item.title,
            message: item.message,
            time: item.time,
            icon: item.read ? Icons.notifications : Icons.notifications_active,
            iconColor: item.read ? const Color(AppColors.textMuted) : green,
            done: item.read,
            dismissDirection: DismissDirection.none,
            onTap: () async {
              await service.markRead(item.id);
              await _loadData();
              if (!mounted) return;
              if (item.id.startsWith("weekly_insights_")) {
                mainNavIndex.value = 3;
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildInboxList() {
    if (inboxTasks.isEmpty) {
      return const Center(
        child: Text(
          "No inbox tasks yet.",
          style: TextStyle(color: Color(AppColors.textMuted)),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: inboxTasks.length,
        itemBuilder: (context, index) {
          final task = inboxTasks[index];
          final missionLine =
              task.mission == null ? "Inbox" : "Mission: ${task.mission}";
          return _buildSwipeNotification(
            key: ValueKey("inbox_${task.id}"),
            title: task.title,
            message: missionLine,
            time: "Recently",
            icon: Icons.inbox,
            iconColor: green,
            onTap: () => _openQuickTaskAssignmentSheet(task),
            dismissDirection: DismissDirection.endToStart,
            onDismissed: (_) async {
              final removedTask = task;
              setState(() {
                inboxTasks.removeAt(index);
              });
              try {
                await _taskService.deleteTask(removedTask.id);
              } catch (e) {
                if (!mounted) return;
                setState(() {
                  inboxTasks.insert(index, removedTask);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Failed to delete task: $e")),
                );
              }
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildTabs(),
            const Divider(color: Color(AppColors.surfaceBase), thickness: 1),
            Expanded(
              child: TabBarView(
                controller: tabController,
                children: [
                  _buildNotificationsList(),
                  _buildInboxList(),
                  _buildNotificationsList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
