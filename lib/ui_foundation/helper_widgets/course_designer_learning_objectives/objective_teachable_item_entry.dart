import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/teachable_item.dart';
import 'package:social_learning/data/learning_objective.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/decomposed_course_designer_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_learning_objectives/learning_objectives_context.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/tag_pill.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_learning_objectives/add_teachable_item_fanout_widget.dart';

class ObjectiveTeachableItemEntry extends StatelessWidget {
  final LearningObjective objective;
  final TeachableItem item;
  final LearningObjectivesContext objectivesContext;

  const ObjectiveTeachableItemEntry({
    super.key,
    required this.objective,
    required this.item,
    required this.objectivesContext,
  });

  @override
  Widget build(BuildContext context) {
    // Build TagPill list with 4px left padding each
    final tagWidgets = (item.tagIds ?? <DocumentReference>[])
        .map((ref) => objectivesContext.tagById[ref.id])
        .where((tag) => tag != null)
        .map((tag) => Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: TagPill(
        label: tag!.name,
        color: Color(int.parse(tag.color.replaceFirst('#', '0xff'))),
      ),
    ))
        .toList();

    return DecomposedCourseDesignerCard.buildBody(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            // Item name
            Expanded(
              child: Text(
                item.name ?? '(Untitled)',
                style: Theme.of(context).textTheme.bodyText1,
              ),
            ),

            // Tags
            ...tagWidgets,

            const SizedBox(width: 8),

            // Edit (replace) icon
            CompositedTransformTarget(
              link: objectivesContext.layerLinkForObjective(objective.id!),
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () {
                  AddTeachableItemFanoutWidget.show(
                    context: context,
                    link: objectivesContext.layerLinkForObjective(objective.id!),
                    objective: objective,
                    objectivesContext: objectivesContext,
                    currentItem: item,
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.edit, size: 18, color: Colors.grey),
                ),
              ),
            ),

            const SizedBox(width: 6),

            // Remove (unlink) icon
            InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () {
                objectivesContext.removeTeachableItemFromObjective(
                  objective: objective,
                  item: item,
                );
              },
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.link_off, size: 18, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
