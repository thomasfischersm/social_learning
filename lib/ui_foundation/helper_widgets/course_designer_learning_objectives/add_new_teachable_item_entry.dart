import 'package:flutter/material.dart';
import 'package:social_learning/data/learning_objective.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/decomposed_course_designer_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_learning_objectives/learning_objectives_context.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_learning_objectives/add_teachable_item_fanout_widget.dart';

class AddTeachableItemEntry extends StatefulWidget {
  final LearningObjective objective;
  final LearningObjectivesContext objectivesContext;

  const AddTeachableItemEntry({
    super.key,
    required this.objective,
    required this.objectivesContext,
  });

  @override
  State<AddTeachableItemEntry> createState() => _AddTeachableItemEntryState();
}

class _AddTeachableItemEntryState extends State<AddTeachableItemEntry> {
  final LayerLink _layerLink = LayerLink();

  @override
  Widget build(BuildContext context) {
    return DecomposedCourseDesignerCard.buildBody(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            const Expanded(child: SizedBox()),

            CompositedTransformTarget(
              link: _layerLink,
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () {
                  AddTeachableItemFanoutWidget.show(
                    context: context,
                    link: _layerLink,
                    objective: widget.objective,
                    objectivesContext: widget.objectivesContext,
                    currentItem: null,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: const [
                      Icon(Icons.add_circle_outline, size: 18, color: Colors.grey),
                      SizedBox(width: 4),
                      Text('Add teachable item to this objective'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
