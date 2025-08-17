import 'package:flutter/material.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

/// Tab bar for navigating the Course Designer flow.
/// Each tab represents a page; tapping navigates to that page without
/// providing swipeable tab views.
class CourseDesignerTabBar extends StatefulWidget implements PreferredSizeWidget {
  final NavigationEnum currentNav;

  const CourseDesignerTabBar({super.key, required this.currentNav});

  static const List<_TabInfo> _tabs = [
    _TabInfo(
        icon: Icons.info_outline,
        nav: NavigationEnum.courseDesignerIntro,
        label: 'Intro'),
    _TabInfo(
        icon: Icons.person_outline,
        nav: NavigationEnum.courseDesignerProfile,
        label: 'Profile'),
    _TabInfo(
        icon: Icons.lightbulb_outline,
        nav: NavigationEnum.courseDesignerInventory,
        label: 'Inventory'),
    _TabInfo(
        icon: Icons.account_tree_outlined,
        nav: NavigationEnum.courseDesignerPrerequisites,
        label: 'Prerequisites'),
    _TabInfo(
        icon: Icons.shopping_cart_outlined,
        nav: NavigationEnum.courseDesignerScope,
        label: 'Scoping'),
    _TabInfo(
        icon: Icons.flag_outlined,
        nav: NavigationEnum.courseDesignerLearningObjectives,
        label: 'Objectives'),
    _TabInfo(
        icon: Icons.event,
        nav: NavigationEnum.courseDesignerSessionPlan,
        label: 'Session Plan'),
  ];

  /// Returns the tab index for a [NavigationEnum].
  static int indexFromNav(NavigationEnum nav) {
    return _tabs.indexWhere((t) => t.nav == nav);
  }

  @override
  Size get preferredSize => const Size.fromHeight(kTextTabBarHeight);

  @override
  State<CourseDesignerTabBar> createState() => _CourseDesignerTabBarState();
}

class _CourseDesignerTabBarState extends State<CourseDesignerTabBar>
    with SingleTickerProviderStateMixin {
  late final TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(
      length: CourseDesignerTabBar._tabs.length,
      vsync: this,
      initialIndex: CourseDesignerTabBar.indexFromNav(widget.currentNav),
    );
  }

  @override
  void didUpdateWidget(covariant CourseDesignerTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentNav != widget.currentNav) {
      _controller.index = CourseDesignerTabBar.indexFromNav(widget.currentNav);
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
        for (final t in CourseDesignerTabBar._tabs)
          Tab(icon: Tooltip(message: t.label, child: Icon(t.icon))),
      ],
      onTap: (i) {
        final nav = CourseDesignerTabBar._tabs[i].nav;
        if (nav != widget.currentNav) {
          nav.navigateClean(context);
        }
      },
    );
  }
}

class _TabInfo {
  final IconData icon;
  final NavigationEnum nav;
  final String label;

  const _TabInfo({required this.icon, required this.nav, required this.label});
}

