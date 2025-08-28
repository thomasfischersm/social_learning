import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/state/course_designer_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'skill_rubric_drag_helper.dart';
import 'skill_rubric_row.dart';
import 'skill_dimension_row.dart';
import 'skill_degree_row.dart';
import 'skill_lesson_row.dart';
import 'new_skill_lesson_row.dart';
import 'new_skill_degree_row.dart';
import 'new_skill_dimension_row.dart';
import 'dimension_footer_row.dart';

class SkillRubricListViewCard extends StatelessWidget {
  const SkillRubricListViewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<CourseDesignerState, LibraryState>(
      builder: (context, state, library, child) {
        final rows = _buildRows(state, library);
        return ReorderableListView(
          buildDefaultDragHandles: false,
          onReorder: (oldIndex, newIndex) async {
            await SkillRubricDragHelper.handleReorder(
              state: state,
              rows: rows,
              oldIndex: oldIndex,
              newIndex: newIndex,
            );
          },
          children: [
            for (final row in rows)
              KeyedSubtree(
                key: PageStorageKey(row.pageKey),
                child: row as Widget,
              ),
          ],
        );
      },
    );
  }

  List<SkillRubricRow> _buildRows(
      CourseDesignerState state, LibraryState library) {
    final rows = <SkillRubricRow>[];
    final rubric = state.skillRubric;

    if (rubric != null) {
      for (final dim in rubric.dimensions) {
        rows.add(SkillDimensionRow(
          dimension: dim,
          state: state,
          dragHandleIndex: rows.length,
        ));
        for (final degree in dim.degrees) {
          rows.add(SkillDegreeRow(
            dimension: dim,
            degree: degree,
            state: state,
            dragHandleIndex: rows.length,
          ));
          for (final ref in degree.lessonRefs) {
            final lesson = library.findLesson(ref.id);
            if (lesson != null) {
              rows.add(SkillLessonRow(
                dimension: dim,
                degree: degree,
                lesson: lesson,
                state: state,
                library: library,
                dragHandleIndex: rows.length,
              ));
            }
          }
          rows.add(NewSkillLessonRow(
            dimension: dim,
            degree: degree,
            state: state,
            library: library,
          ));
        }
        rows.add(NewSkillDegreeRow(
          dimension: dim,
          state: state,
        ));
        rows.add(DimensionFooterRow(dimensionId: dim.id));
      }
    }

    rows.add(NewSkillDimensionRow(state: state));
    return rows;
  }
}
