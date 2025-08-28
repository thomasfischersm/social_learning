import 'package:flutter/material.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/skill_rubric.dart';
import 'package:social_learning/data/data_helpers/skill_rubrics_functions.dart';
import 'package:social_learning/state/course_designer_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/lesson_detail_page.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/decomposed_course_designer_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/dialog_utils.dart';
import 'skill_rubric_lesson_fanout_widget.dart';

class SkillLessonRow extends StatefulWidget {
  final SkillDimension dimension;
  final SkillDegree degree;
  final Lesson lesson;
  final CourseDesignerState state;
  final LibraryState library;

  const SkillLessonRow({
    super.key,
    required this.dimension,
    required this.degree,
    required this.lesson,
    required this.state,
    required this.library,
  });

  @override
  State<SkillLessonRow> createState() => _SkillLessonRowState();
}

class _SkillLessonRowState extends State<SkillLessonRow> {
  final LayerLink _layerLink = LayerLink();

  void _replace() {
    final exclude = widget.degree.lessonRefs.map((e) => e.id).toSet()
      ..remove(widget.lesson.id);
    SkillRubricLessonFanoutWidget.show(
      context: context,
      link: _layerLink,
      libraryState: widget.library,
      excludeLessonIds: exclude,
      onSelected: (selected) async {
        final courseId = widget.state.course?.id;
        if (courseId == null) return;
        final removed = await SkillRubricsFunctions.removeLesson(
          courseId: courseId,
          dimensionId: widget.dimension.id,
          degreeId: widget.degree.id,
          lessonId: widget.lesson.id!,
        );
        if (removed != null) {
          final updated = await SkillRubricsFunctions.addLesson(
            courseId: courseId,
            dimensionId: widget.dimension.id,
            degreeId: widget.degree.id,
            lessonId: selected.id!,
          );
          if (updated != null) {
            widget.state.skillRubric = updated;
            widget.state.notifyListeners();
          }
        }
      },
    );
  }

  void _delete() {
    final courseId = widget.state.course?.id;
    if (courseId == null) return;
    DialogUtils.showConfirmationDialog(
      context,
      'Remove lesson?',
      'Detach "${widget.lesson.title}" from this degree?',
      () async {
        final updated = await SkillRubricsFunctions.removeLesson(
          courseId: courseId,
          dimensionId: widget.dimension.id,
          degreeId: widget.degree.id,
          lessonId: widget.lesson.id!,
        );
        if (updated != null) {
          widget.state.skillRubric = updated;
          widget.state.notifyListeners();
        }
      },
    );
  }

  void _openLesson() {
    final lessonId = widget.lesson.id;
    if (lessonId != null) {
      LessonDetailArgument.goToLessonDetailPage(context, lessonId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecomposedCourseDesignerCard.buildBody(
      Padding(
        padding: const EdgeInsets.fromLTRB(32, 8, 16, 8),
        child: Row(
          children: [
            InkWell(
              onTap: _openLesson,
              child: Text(widget.lesson.title),
            ),
            const SizedBox(width: 8),
            CompositedTransformTarget(
              link: _layerLink,
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: _replace,
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(Icons.edit, size: 18, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: _delete,
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(Icons.close, size: 18, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
