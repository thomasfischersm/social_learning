import 'package:flutter/material.dart';
import 'package:social_learning/data/teachable_item.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/course_designer_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_prerequisites/prerequisite_context.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_prerequisites/prerequisite_item_entry.dart';

class PrerequisitesCard extends StatelessWidget {
  final PrerequisiteContext context;
  final TeachableItem? focusedItem;

  const PrerequisitesCard({
    super.key,
    required this.context,
    required this.focusedItem,
  });

  List<PrerequisiteItemEntry> _buildWrappedEntries(
      List<TeachableItem> prerequisites,
      TeachableItem parent,
      int depth,
      ) {
    final entries = <PrerequisiteItemEntry>[];
    for (final prereq in prerequisites) {
      entries.add(PrerequisiteItemEntry(
        context: context,
        item: prereq,
        parentItem: parent,
        parentDepth: depth,
      ));
      entries.addAll(_buildWrappedEntries(
        context.getAllPrerequisites(prereq),
        prereq,
        depth + 1,
      ));
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    if (focusedItem == null) {
      return CourseDesignerCard(
        title: 'Dependency Tree',
        body: const Text('No item selected.'),
      );
    }

    final allPrerequisites = this.context.getAllPrerequisites(focusedItem!);
    final entries = _buildWrappedEntries(allPrerequisites, focusedItem!, 0);

    return CourseDesignerCard(
      title: 'Dependency Tree',
      body: entries.isEmpty
          ? const Text('No prerequisites defined.')
          : Column(children: entries),
    );
  }
}
