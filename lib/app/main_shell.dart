import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sptm/views/archive/archive_page.dart';
import 'package:sptm/views/calendar/calendar_page.dart';
import 'package:sptm/views/dashboard/dashboard_page.dart';
import 'package:sptm/views/insights/insights_page.dart';
import 'package:sptm/views/missions/missions_list_page.dart';
import 'package:sptm/core/constants.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  final pages = const [
    DashboardPage(),
    MissionsListPage(),
    CalendarPage(),
    InsightsPage(),
    ArchivePage(),
  ];

  Widget _navItem({required IconData icon, required int itemIndex}) {
    final isActive = index == itemIndex;

    return InkWell(
      onTap: () => setState(() => index = itemIndex),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isActive
              ? const Color(AppColors.primary).withOpacity(0.2)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive
              ? const Color(AppColors.textMain)
              : const Color(AppColors.textMuted),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: SafeArea(
        top: false,
        child: BottomAppBar(
          color: const Color(AppColors.background),
          surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
          shape: const CircularNotchedRectangle(),
          notchMargin: 6,
          elevation: 3,
          child: SizedBox(
            height: 52,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(icon: Icons.home, itemIndex: 0), // dashboard
                _navItem(
                  icon: Icons.track_changes_rounded,
                  itemIndex: 1,
                ), // missions
                _navItem(icon: Icons.calendar_month, itemIndex: 2), // calendar
                _navItem(icon: Icons.insights, itemIndex: 3), // insights
                _navItem(
                  icon: CupertinoIcons.archivebox_fill,
                  itemIndex: 4,
                ), // archive
              ],
            ),
          ),
        ),
      ),
    );
  }
}
