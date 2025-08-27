import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/data_helpers/belt_color_functions.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/student_state.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';

class ProgressCard extends StatelessWidget {
  const ProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<StudentState, LibraryState>(
        builder: (context, studentState, libraryState, child) {
      Course? course = libraryState.selectedCourse;
      var lessons = libraryState.lessons;
      if (course == null || lessons == null) {
        return const SizedBox.shrink();
      }
      int totalLessons =
          lessons.where((l) => l.courseId.id == course.id).length;
      int completed = studentState.getLessonsLearned(course, libraryState);
      double progress =
          totalLessons == 0 ? 0 : completed / totalLessons.toDouble();
      Color beltColor = BeltColorFunctions.getBeltColor(progress);

      // Determine if the next lesson card is small (no cover image or all lessons learned)
      bool shortText = false;
      List<String> completedIds = studentState.getGraduatedLessonIds();
      List<Lesson> remaining = lessons
          .where((l) => l.courseId.id == course.id)
          .where((l) => !completedIds.contains(l.id))
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      if (remaining.isEmpty || remaining.first.coverFireStoragePath == null) {
        shortText = true;
      }

      const double strokeWidth = 6;
      return Card(
          child: Padding(
        padding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: [
            FittedBox(
              fit: BoxFit.contain,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: strokeWidth,
                color: beltColor,
                backgroundColor: beltColor.withValues(alpha:.25),
              ),
            ),
            Center(
              child: Text(
                  shortText
                      ? '$completed / $totalLessons'
                      : '$completed of $totalLessons\nlessons\ncompleted',
                  textAlign: TextAlign.center,
                  style: CustomTextStyles.getBody(context)),
            ),
          ],
        ),
      ));
    });
  }
}

