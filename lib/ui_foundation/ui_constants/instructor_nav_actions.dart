import 'package:flutter/material.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

class InstructorNavActions {
  static List<IconButton> createActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.account_tree_outlined),
        tooltip: 'Course Designer', // Updated tooltip
        onPressed: () =>
            NavigationEnum.courseDesignerIntro.navigateClean(context),
      )
    ];
  }
}
