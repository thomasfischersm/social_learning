import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/state/course_designer_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/decomposed_course_designer_card.dart';
import 'new_skill_degree_row.dart';
import 'new_skill_dimension_row.dart';
import 'new_skill_lesson_row.dart';
import 'skill_degree_row.dart';
import 'skill_dimension_row.dart';
import 'skill_lesson_row.dart';

class SkillRubricListViewCard extends StatelessWidget {
  const SkillRubricListViewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<CourseDesignerState, LibraryState>(
      builder: (context, state, library, child) {
        final children = <Widget>[];
        final rubric = state.skillRubric;

        if (rubric != null) {
          for (final dim in rubric.dimensions) {
            children.add(SkillDimensionRow(dimension: dim, state: state));
            for (final degree in dim.degrees) {
              children.add(
                SkillDegreeRow(dimension: dim, degree: degree, state: state),
              );
              for (final ref in degree.lessonRefs) {
                final lesson = library.findLesson(ref.id);
                if (lesson != null) {
                  children.add(
                    SkillLessonRow(
                      dimension: dim,
                      degree: degree,
                      lesson: lesson,
                      state: state,
                      library: library,
                    ),
                  );
                }
              }
              children.add(NewSkillLessonRow(
                dimension: dim,
                degree: degree,
                state: state,
                library: library,
              ));
            }
            children.add(NewSkillDegreeRow(dimension: dim, state: state));
            children.add(
              DecomposedCourseDesignerCard.buildFooter(bottomMargin: 16),
            );
          }
        }
        children.add(NewSkillDimensionRow(state: state));

        return ListView(children: children);
      },
    );
  }
}
