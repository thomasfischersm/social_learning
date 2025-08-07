import 'package:flutter/material.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

/// Default app bar for signed-in pages.
/// Displays a title and a course switching icon.
class LearningLabAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const LearningLabAppBar({super.key, required this.title, this.actions});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: [
        IconButton(
          onPressed: () => NavigationEnum.home.navigateClean(context),
          icon: const Icon(Icons.swap_horiz),
        ),
        ...?actions,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
