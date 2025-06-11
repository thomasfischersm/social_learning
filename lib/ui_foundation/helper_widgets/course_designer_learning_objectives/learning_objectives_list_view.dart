import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/decomposed_course_designer_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_learning_objectives/learning_objectives_context.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_learning_objectives/learning_objective_entry.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_learning_objectives/add_new_objective_entry.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_learning_objectives/objective_teachable_item_entry.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_learning_objectives/objective_lesson_entry.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_learning_objectives/add_lesson_entry.dart';

import 'add_new_teachable_item_entry.dart';

class LearningObjectivesListView extends StatelessWidget {
  final LearningObjectivesContext objectivesContext;

  const LearningObjectivesListView({
    Key? key,
    required this.objectivesContext,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final library = Provider.of<LibraryState>(context, listen: false);
    final rows = <Widget>[];

    // Bottom card header
    rows.add(
      DecomposedCourseDesignerCard.buildHeader(
        'Map learning outcomes → what → how',
      ),
    );

    // Build entries for each objective
    for (final objective in objectivesContext.learningObjectives) {
      // Objective header + description
      rows.add(
        LearningObjectiveEntry(
          objective: objective,
          objectivesContext: objectivesContext,
        ),
      );

      // Teachable items under this objective
      for (final itemRef in objective.teachableItemRefs) {
        final item = objectivesContext.itemById[itemRef.id]!;

        rows.add(
          ObjectiveTeachableItemEntry(
            objective: objective,
            item: item,
            objectivesContext: objectivesContext,
          ),
        );

        // Lessons under this teachable item
        for (final lessonRef in item.lessonRefs ?? []) {
          final lesson = library.findLesson(lessonRef.id)!;
          rows.add(
            ObjectiveLessonEntry(
              item: item,
              lesson: lesson,
              objectivesContext: objectivesContext,
            ),
          );
        }

        // Row to add a lesson
        rows.add(
          AddLessonEntry(
            item: item,
            objectivesContext: objectivesContext,
          ),
        );
      }

      // Row to add a teachable item
      rows.add(
        AddTeachableItemEntry(
          objective: objective,
          objectivesContext: objectivesContext,
        ),
      );
    }

    // Row to add a new learning objective
    rows.add(
      AddNewObjectiveEntry(
        objectivesContext: objectivesContext,
      ),
    );

    // Bottom card footer
    rows.add(
      DecomposedCourseDesignerCard.buildFooter(),
    );

    return ListView(children: rows);
  }
}
