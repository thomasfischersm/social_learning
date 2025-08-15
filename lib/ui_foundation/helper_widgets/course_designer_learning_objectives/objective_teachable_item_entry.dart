import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/teachable_item.dart';
import 'package:social_learning/data/learning_objective.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/decomposed_course_designer_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/tag_pill.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_learning_objectives/learning_objectives_context.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_learning_objectives/add_teachable_item_fanout_widget.dart';

import '../../ui_constants/custom_text_styles.dart';

class ObjectiveTeachableItemEntry extends StatefulWidget {
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
  _ObjectiveTeachableItemEntryState createState() =>
      _ObjectiveTeachableItemEntryState();
}

class _ObjectiveTeachableItemEntryState
    extends State<ObjectiveTeachableItemEntry> {
  final LayerLink _link = LayerLink();

  @override
  Widget build(BuildContext context) {
    final tagWidgets = (widget.item.tagIds ?? <DocumentReference>[])
        .map((ref) => widget.objectivesContext.tagById[ref.id])
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
            Flexible(child:Text(
                widget.item.name ?? '(Untitled)',
              softWrap: true)),


            // Tags
            ...tagWidgets,

            const SizedBox(width: 8),

            // ✏️ Edit (replace) icon with its own LayerLink
            CompositedTransformTarget(
              link: _link,
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () {
                  AddTeachableItemFanoutWidget.show(
                    context: context,
                    link: _link,
                    objective: widget.objective,
                    objectivesContext: widget.objectivesContext,
                    currentItem: widget.item,
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.edit, size: 18, color: Colors.grey),
                ),
              ),
            ),

            const SizedBox(width: 6),

            // 🔗 off remove icon
            InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () {
                widget.objectivesContext.removeTeachableItemFromObjective(
                  objective: widget.objective,
                  item: widget.item,
                );
              },
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, size: 18, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
