import 'package:flutter/material.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

/// Navigation tab bar for the instructor flow pages.
class InstructorDashboardTabBar extends StatefulWidget
    implements PreferredSizeWidget {
  final NavigationEnum currentNav;

  const InstructorDashboardTabBar({
    super.key,
    required this.currentNav,
  });

  static const List<_TabInfo> _tabs = [
    _TabInfo(
      icon: Icons.dashboard_outlined,
      nav: NavigationEnum.instructorDashBoard,
      label: 'Dashboard',
    ),
    _TabInfo(
      icon: Icons.people_outline,
      nav: NavigationEnum.studentPopulationAnalytics,
      label: 'Student Analytics',
    ),
    _TabInfo(
      icon: Icons.history,
      nav: NavigationEnum.studyHistoryAnlytics,
      label: 'Study History',
    ),
    _TabInfo(
      icon: Icons.hub_outlined,
      nav: NavigationEnum.studentNetworkAnalytics,
      label: 'Network Analytics',
    ),
    _TabInfo(
      icon: Icons.rate_review_outlined,
      nav: NavigationEnum.commentReview,
      label: 'Comment Review',
    ),
  ];

  static int indexFromNav(NavigationEnum nav) {
    final index = _tabs.indexWhere((t) => t.nav == nav);
    return index == -1 ? 0 : index;
  }

  @override
  Size get preferredSize => const Size.fromHeight(kTextTabBarHeight);

  @override
  State<InstructorDashboardTabBar> createState() =>
      _InstructorDashboardTabBarState();
}

class _InstructorDashboardTabBarState extends State<InstructorDashboardTabBar>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(
      length: InstructorDashboardTabBar._tabs.length,
      vsync: this,
      initialIndex: InstructorDashboardTabBar.indexFromNav(widget.currentNav),
    );
  }

  @override
  void didUpdateWidget(covariant InstructorDashboardTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentNav != widget.currentNav) {
      _controller.index =
          InstructorDashboardTabBar.indexFromNav(widget.currentNav);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: _controller,
      tabs: [
        for (final tab in InstructorDashboardTabBar._tabs)
          Tab(
            icon: Tooltip(
              message: tab.label,
              child: Icon(tab.icon),
            ),
          ),
      ],
      onTap: (index) {
        final targetNav = InstructorDashboardTabBar._tabs[index].nav;
        if (targetNav != widget.currentNav) {
          targetNav.navigateClean(context);
        }
      },
    );
  }
}

class _TabInfo {
  final IconData icon;
  final NavigationEnum nav;
  final String label;

  const _TabInfo({
    required this.icon,
    required this.nav,
    required this.label,
  });
}

