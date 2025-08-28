import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/state/course_designer_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'skill_rubric_drag_helper.dart';
import 'skill_rubric_entry.dart';

class SkillRubricListViewCard extends StatelessWidget {
  const SkillRubricListViewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<CourseDesignerState, LibraryState>(
      builder: (context, state, library, child) {
        final entries = _buildEntries(state, library);
        return ReorderableListView.builder(
          buildDefaultDragHandles: false,
          itemCount: entries.length,
          onReorder: (oldIndex, newIndex) async {
            await SkillRubricDragHelper.handleReorder(
              state: state,
              entries: entries,
              oldIndex: oldIndex,
              newIndex: newIndex,
            );
          },
          itemBuilder: (context, index) {
            final entry = entries[index];
            return KeyedSubtree(
              key: PageStorageKey(entry.pageKey),
              child: entry.buildWidget(context, state, library, index),
            );
          },
        );
      },
    );
  }

  List<SkillRubricEntry> _buildEntries(
      CourseDesignerState state, LibraryState library) {
    final entries = <SkillRubricEntry>[];
    final rubric = state.skillRubric;

    if (rubric != null) {
      for (final dim in rubric.dimensions) {
        entries.add(SkillDimensionEntry(dim));
        for (final degree in dim.degrees) {
          entries.add(SkillDegreeEntry(dim, degree));
          for (final ref in degree.lessonRefs) {
            final lesson = library.findLesson(ref.id);
            if (lesson != null) {
              entries.add(SkillLessonEntry(dim, degree, lesson));
            }
          }
          entries.add(NewSkillLessonEntry(dim, degree));
        }
        entries.add(NewSkillDegreeEntry(dim));
        entries.add(DimensionFooterEntry(dim.id));
      }
    }

    entries.add(NewSkillDimensionEntry());
    return entries;
  }
}
