import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/student_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/lesson_cover_image_widget.dart';
import 'package:social_learning/ui_foundation/lesson_detail_page.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';

class NextLessonCard extends StatelessWidget {
  const NextLessonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<StudentState, LibraryState>(
        builder: (context, studentState, libraryState, child) {
      var lessons = libraryState.lessons;
      var course = libraryState.selectedCourse;
      if (lessons == null || course == null) {
        return const SizedBox.shrink();
      }
      List<String> completed = studentState.getGraduatedLessonIds();
      List<Lesson> remaining = lessons
          .where((l) => l.courseId.id == course.id)
          .where((l) => !completed.contains(l.id))
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      if (remaining.isEmpty) {
        return Card(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('All lessons completed!',
                    style: CustomTextStyles.getBody(context))));
      }
      Lesson lesson = remaining.first;
      return Card(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LessonCoverImageWidget(lesson.coverFireStoragePath),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child:
                Text(lesson.title, style: CustomTextStyles.getBody(context)),
          ),
          Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 8),
                  child: ElevatedButton.icon(
                      onPressed: () =>
                          LessonDetailArgument.goToLessonDetailPage(
                              context, lesson.id!),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start'))))
        ],
      ));
    });
  }
}

