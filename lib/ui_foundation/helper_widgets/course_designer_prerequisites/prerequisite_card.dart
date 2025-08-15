import 'package:flutter/material.dart';
import 'package:social_learning/data/teachable_item.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/course_designer_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/decomposed_course_designer_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_prerequisites/prerequisite_context.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_prerequisites/prerequisite_item_entry.dart';

class PrerequisitesCard extends StatelessWidget {
  final PrerequisiteContext context;
  final TeachableItem? focusedItem;
  final void Function(String? selectedItemId) onSelectItem;

  const PrerequisitesCard({
    super.key,
    required this.context,
    required this.focusedItem,
    required this.onSelectItem,
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
        showAddButton: true,
      ));
      entries.addAll(_buildWrappedEntries(
        context.getAllPrerequisites(prereq),
        prereq,
        depth + 1,
      ));
    }
    return entries;
  }

  Widget _buildViewForFocusedItem() {
    final prerequisites = context.getAllPrerequisites(focusedItem!);

    final entries = <PrerequisiteItemEntry>[
      PrerequisiteItemEntry(
        key: UniqueKey(),
        context: context,
        item: focusedItem!,
        parentItem: null,
        parentDepth: 0,
        showAddButton: true,
      ),
      ..._buildWrappedEntries(
        prerequisites,
        focusedItem!,
        1,
      ),
    ];

    return ListView.builder(
      itemCount: entries.length + 1,
      itemBuilder: (context, index) {
        if (index < entries.length) {
          return entries[index];
        } else {
          return DecomposedCourseDesignerCard.buildFooter();
        }
      },
    );
  }

  Widget _buildViewForAllItemsWithDependencies() {
    final rootItems = context.getItemsWithDependencies();
    final entries = <PrerequisiteItemEntry>[];

    for (final root in rootItems) {
      entries.add(PrerequisiteItemEntry(
        key: UniqueKey(),
        context: context,
        item: root,
        parentItem: null,
        parentDepth: 0,
        showAddButton: true,
      ));

      for (final prereq in context.getAllPrerequisites(root)) {
        entries.add(PrerequisiteItemEntry(
          key: UniqueKey(),
          context: context,
          item: prereq,
          parentItem: root,
          parentDepth: 1,
          showAddButton: false,
          onSelectItem: onSelectItem,
        ));
      }
    }

    return SizedBox.expand(child:ListView.builder(
      itemCount: entries.length + 1,
      itemBuilder: (context, index) {
        if (index < entries.length) {
          return entries[index];
        } else {
          return DecomposedCourseDesignerCard.buildFooter();
        }
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    print('Building prerequisites card for: ${focusedItem?.name ?? 'null'}');
    return focusedItem == null
        ? _buildViewForAllItemsWithDependencies()
        : _buildViewForFocusedItem();
  }
}
