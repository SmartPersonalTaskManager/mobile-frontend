import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sptm/core/constants.dart';
import 'package:sptm/services/task_service.dart';
import 'package:sptm/views/notifications/notifications_page.dart';
import 'package:sptm/views/settings/settings_page.dart';

class SPTMAppBar extends StatefulWidget implements PreferredSizeWidget {
  const SPTMAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? leading;

  @override
  State<SPTMAppBar> createState() => _SPTMAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _SPTMAppBarState extends State<SPTMAppBar> {
  final TaskService _taskService = TaskService();
  bool _hasInboxItems = false;

  @override
  void initState() {
    super.initState();
    _refreshInboxBadge();
  }

  Future<void> _refreshInboxBadge() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("userId");
    if (userId == null) {
      if (!mounted) return;
      setState(() => _hasInboxItems = false);
      return;
    }

    try {
      final tasks = await _taskService.getTasks(userId);
      final hasInbox = tasks.any((task) => task.isInbox && !task.isArchived);
      if (!mounted) return;
      setState(() => _hasInboxItems = hasInbox);
    } catch (_) {
      if (!mounted) return;
      setState(() => _hasInboxItems = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(AppColors.background),
      elevation: 0,
      leadingWidth: 160,
      leading: Padding(
        padding: EdgeInsets.only(left: 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              widget.title,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(AppColors.textMain),
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications,
                color: Color(AppColors.textMain),
              ),
              if (_hasInboxItems)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(AppColors.danger),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const NotificationsPage(),
              ),
            );
            await _refreshInboxBadge();
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings, color: Color(AppColors.textMain)),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            );
          },
        ),
      ],
    );
  }
}
