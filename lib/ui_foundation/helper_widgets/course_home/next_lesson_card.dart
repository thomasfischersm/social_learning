import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/skill_rubric.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/student_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_home/next_skill_lesson_recommender.dart';
import 'package:social_learning/ui_foundation/helper_widgets/lesson_cover_image_widget.dart';
import 'package:social_learning/ui_foundation/lesson_detail_page.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';

class NextLessonCard extends StatelessWidget {
  final Lesson? _lesson;

  const NextLessonCard({super.key, required Lesson? lesson}) : _lesson = lesson;

  factory NextLessonCard.forKnowledge(
      LibraryState libraryState, StudentState studentState) {
    var lessons = libraryState.lessons;
    var course = libraryState.selectedCourse;
    if (lessons == null || course == null) {
      return NextLessonCard(lesson: null);
    }

    List<String> completed = studentState.getGraduatedLessonIds();
    List<Lesson> remaining = lessons
        .where((l) => l.courseId.id == course.id)
        .where((l) => !completed.contains(l.id))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    if (remaining.isEmpty) {
      return NextLessonCard(lesson: null);
    } else {
      return NextLessonCard(lesson: remaining.first);
    }
  }

  factory NextLessonCard.forSkill(
      LibraryState libraryState,
      StudentState studentState,
      ApplicationState applicationState,
      SkillRubric skillRubric) {
    Lesson? nextLesson = NextSkillLessonRecommender.recommendNextLesson(
        libraryState, applicationState, studentState, skillRubric);
    return NextLessonCard(lesson: nextLesson);
  }

  @override
  Widget build(BuildContext context) {
    if (_lesson == null) {
      return Card(
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('All lessons completed!',
                  style: CustomTextStyles.getBody(context))));
    }

    return Card(
      clipBehavior: Clip.antiAlias,
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        LessonCoverImageWidget(_lesson!.coverFireStoragePath),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('Next lesson', style: CustomTextStyles.subHeadline),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(_lesson!.title, style: CustomTextStyles.getBody(context)),
        ),
        Align(
            alignment: Alignment.centerRight,
            child: Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 8, top: 8),
                child: ElevatedButton(
                    onPressed: () => LessonDetailArgument.goToLessonDetailPage(
                        context, _lesson!.id!),
                    child: const Icon(Icons.play_arrow))))
      ],
    ));
  }
}
