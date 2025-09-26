import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/instructor_dashboard/instructor_dashboard_tab_bar.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

/// App bar for instructor flow pages.
/// Mirrors the shared Learning Lab app bar while hosting the flow tab bar.
class InstructorDashboardAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final NavigationEnum currentNav;
  final String? title;
  final List<Widget>? actions;

  const InstructorDashboardAppBar({
    super.key,
    required this.currentNav,
    this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final courseTitle = context.read<LibraryState>().selectedCourse?.title;
    final displayTitle = title ??
        (courseTitle != null ? 'Learning Lab: $courseTitle' : 'Learning Lab');

    return AppBar(
      title: Text(displayTitle),
      actions: [
        IconButton(
          onPressed: () => NavigationEnum.home.navigateClean(context),
          icon: const Icon(Icons.swap_horiz),
        ),
        ...?actions,
      ],
      bottom: InstructorDashboardTabBar(currentNav: currentNav),
    );
  }

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight + kTextTabBarHeight);
}
