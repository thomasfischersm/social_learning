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
        key: UniqueKey(),
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
    print('Building prerequisites card for: ${focusedItem?.name ?? 'null'}');

    if (focusedItem == null) {
      return CourseDesignerCard(
        title: 'Dependency Tree',
        body: const Text('No item selected.'),
      );
    }

    final entries = <PrerequisiteItemEntry>[
      // Add the focused item itself as root
      PrerequisiteItemEntry(
        key: UniqueKey(),
        context: this.context,
        item: focusedItem!,
        parentItem: null,
        parentDepth: 0, // special marker for root; or use 0
      ),
      // Then add its prerequisites recursively
      ..._buildWrappedEntries(
        this.context.getAllPrerequisites(focusedItem!),
        focusedItem!,
        1,
      ),
    ];

    return CourseDesignerCard(
      title: 'Dependency Tree',
      body: entries.isEmpty
          ? const Text('No prerequisites defined.')
          : SizedBox(
        height: 400,
        child: ListView.builder(
          itemCount: entries.length,
          itemBuilder: (context, index) => entries[index],
        ),
      ),
    );
  }

}
