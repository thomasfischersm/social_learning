import 'package:flutter/material.dart';
import 'package:social_learning/state/course_designer_state.dart';

abstract class InventoryEntry {
  /// Unique identifier used as a [PageStorageKey] so Flutter can maintain
  /// the scroll position of this entry within the inventory list.
  String get pageKey;

  Widget buildWidget(
      BuildContext context, VoidCallback refresh, CourseDesignerState state);
}
