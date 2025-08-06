import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/course.dart';
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
      const double strokeWidth = 8;
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
                backgroundColor: beltColor.withOpacity(.25),
              ),
            ),
            Center(
              child: Text('$completed of $totalLessons\nlessons completed',
                  textAlign: TextAlign.center,
                  style: CustomTextStyles.getBody(context)),
            ),
          ],
        ),
      ));
    });
  }
}

