import 'package:flutter/material.dart';
import 'package:social_learning/state/course_designer_state.dart';

abstract class InventoryEntry {
  Widget buildWidget(
      BuildContext context, VoidCallback refresh, CourseDesignerState state);
}
