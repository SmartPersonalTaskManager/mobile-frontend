import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sptm/core/constants.dart';
import 'package:sptm/services/notification_service.dart';

// TODO if there are quick-add tasks not assigned, show a notification about that

import '../../models/notification_item.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  static const String _inboxKey = "quick_capture_inbox_tasks";
  final Color bg = const Color(AppColors.background);
  final Color cardColor = const Color(AppColors.surface);
  final Color green = const Color(AppColors.primary);
  late TabController tabController;
  late NotificationService service;
  List<NotificationItem> items = [];
  List<_InboxTask> inboxTasks = [];

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 4, vsync: this);
    service = NotificationService();
    _loadData();
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
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
    final rawItems = prefs.getStringList(_inboxKey) ?? [];
    inboxTasks = rawItems
        .map((raw) {
          try {
            return _InboxTask.fromJson(jsonDecode(raw) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<_InboxTask>()
        .toList()
        .reversed
        .toList();
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
    required String title,
    required String message,
    required String time,
    IconData icon = Icons.check,
    Color iconColor = const Color(AppColors.textMuted),
    bool done = false,
  }) {
    return Dismissible(
      key: UniqueKey(),
      background: _buildSwipeBackground(),
      secondaryBackground: _buildSwipeDelete(),
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
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          _buildSectionTitle("NEW"),
          _buildNotificationCardNew(
            icon: Icons.check_circle,
            iconColor: green,
            title: "Due Today: Complete draft for Project Proposal",
            message:
                "The initial draft is due by 5:00 PM. Don't forget to include the budget analysis section.",
            time: "2m ago",
          ),
          _buildNotificationCardNew(
            icon: Icons.flag,
            iconColor: const Color(AppColors.accentPurple),
            title: "Quarterly Mission Statement Review",
            message: "Your scheduled review starts in 10 minutes.",
            time: "1h ago",
            actionButton: _buildSmallActionButton("Start Review"),
          ),
          const SizedBox(height: 20),
          _buildSectionTitle("EARLIER"),
          _buildSwipeNotification(
            title: "Alignment Tip",
            message:
                "You recently linked a task to your 'Health' mission. Try adding a workout or meditation...",
            time: "Yesterday",
          ),
          _buildSwipeNotification(
            title: "Buy Groceries",
            message: "Marked as done from your daily list.",
            time: "Yesterday",
            done: true,
          ),
          _buildSwipeNotification(
            title: "Weekly Retrospective",
            message: "Ready to look back at your week?",
            time: "2 days ago",
            icon: Icons.assignment_turned_in,
            iconColor: const Color(AppColors.secondaryIndigoLight),
          ),
        ],
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
          final missionLine = task.mission == null
              ? "Inbox"
              : "Mission: ${task.mission}";
          return _buildSwipeNotification(
            title: task.title,
            message: missionLine,
            time: "Recently",
            icon: Icons.inbox,
            iconColor: green,
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

class _InboxTask {
  final String title;
  final String? mission;
  final DateTime createdAt;

  const _InboxTask({
    required this.title,
    required this.createdAt,
    this.mission,
  });

  factory _InboxTask.fromJson(Map<String, dynamic> json) {
    return _InboxTask(
      title: (json["title"] as String?) ?? "Untitled",
      mission: json["mission"] as String?,
      createdAt:
          DateTime.tryParse(json["createdAt"] as String? ?? "") ??
          DateTime.now(),
    );
  }
}
