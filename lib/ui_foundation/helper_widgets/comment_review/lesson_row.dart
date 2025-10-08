import 'package:flutter/material.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/lesson_comment.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/decomposed_course_designer_card.dart';
import 'package:social_learning/ui_foundation/lesson_detail_page.dart';

class LessonRow extends StatelessWidget {
  final Lesson _lesson;
  final List<LessonComment> _comments;

  const LessonRow(this._lesson, this._comments, {super.key});

  @override
  Widget build(BuildContext context) {
    return DecomposedCourseDesignerCard.buildHeader(_lesson.title, onTap: () {
      _navigateToLesson(context);
    });
  }

  void _navigateToLesson(BuildContext context) {
    String? lessonId = _lesson.id;

    if (lessonId != null && context.mounted) {
      LessonDetailArgument.goToLessonDetailPage(context, lessonId);
    }
  }
}
