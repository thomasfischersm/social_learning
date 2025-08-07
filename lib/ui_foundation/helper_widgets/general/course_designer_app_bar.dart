import 'package:flutter/material.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/course_designer_drawer.dart';
import 'package:social_learning/ui_foundation/ui_constants/instructor_nav_actions.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

/// App bar used across CourseDesigner pages.
/// Includes drawer toggle, course switch icon, and instructor navigation icons.
class CourseDesignerAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final GlobalKey<ScaffoldState> scaffoldKey;

  const CourseDesignerAppBar({
    super.key,
    required this.title,
    required this.scaffoldKey,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      leading: CourseDesignerDrawer.hamburger(scaffoldKey),
      actions: [
        IconButton(
          onPressed: () => NavigationEnum.home.navigateClean(context),
          icon: const Icon(Icons.swap_horiz),
        ),
        ...InstructorNavActions.createActions(context),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
