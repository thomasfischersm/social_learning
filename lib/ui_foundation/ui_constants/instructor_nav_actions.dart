import 'package:flutter/material.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

class InstructorNavActions {
  static List<IconButton> createActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.bar_chart),
        tooltip: 'Instructor Dashboard',
        onPressed: () =>
            NavigationEnum.instructorDashBoard.navigateClean(context),
      ),
      IconButton(
        icon: const Icon(Icons.auto_stories),
        tooltip: 'Generate Curriculum',
        onPressed: () => NavigationEnum.courseGeneration.navigateClean(context),
      ),
      IconButton(
        icon: const Icon(Icons.account_tree_outlined),
        tooltip: 'Course Designer', // Updated tooltip
        onPressed: () =>
            NavigationEnum.courseDesignerIntro.navigateClean(context),
      )
    ];
  }
}
