import 'package:flutter/material.dart';
import 'package:social_learning/data/skill_rubric.dart';
import 'package:social_learning/data/data_helpers/skill_rubrics_functions.dart';
import 'package:social_learning/state/course_designer_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/cms_lesson_page.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/decomposed_course_designer_card.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';
import 'skill_rubric_lesson_fanout_widget.dart';
import 'skill_rubric_row.dart';

class NewSkillLessonRow extends StatefulWidget implements SkillRubricRow {
  final SkillDimension dimension;
  final SkillDegree degree;
  final CourseDesignerState state;
  final LibraryState library;

  const NewSkillLessonRow({
    super.key,
    required this.dimension,
    required this.degree,
    required this.state,
    required this.library,
  });

  @override
  String get pageKey => 'new-lesson-${degree.id}';

  @override
  State<NewSkillLessonRow> createState() => _NewSkillLessonRowState();
}

class _NewSkillLessonRowState extends State<NewSkillLessonRow> {
  final LayerLink _layerLink = LayerLink();

  void _attach() {
    final exclude = widget.degree.lessonRefs.map((e) => e.id).toSet();
    SkillRubricLessonFanoutWidget.show(
      context: context,
      link: _layerLink,
      libraryState: widget.library,
      excludeLessonIds: exclude,
      onSelected: (lesson) async {
        final courseId = widget.state.course?.id;
        if (courseId == null) return;
        final updated = await SkillRubricsFunctions.addLesson(
          courseId: courseId,
          dimensionId: widget.dimension.id,
          degreeId: widget.degree.id,
          lessonId: lesson.id!,
        );
        if (updated != null) {
          widget.state.skillRubric = updated;
          widget.state.notifyListeners();
        }
      },
    );
  }

  void _createLesson() {
    Navigator.pushNamed(
      context,
      NavigationEnum.cmsLesson.route,
      arguments: CmsLessonDetailArgument.forNewLessonToAttachToSkillDegree(
        degreeId: widget.degree.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecomposedCourseDesignerCard.buildBody(
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 0, 8),
        child: Row(
          children: [
            CompositedTransformTarget(
              link: _layerLink,
              child: InkWell(
                onTap: _attach,
                child: const Text('Attach lesson'),
              ),
            ),
            const SizedBox(width: 16),
            InkWell(
              onTap: _createLesson,
              child: const Text('Create lesson'),
            ),
          ],
        ),
      ),
    );
  }
}
