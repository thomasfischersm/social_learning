import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/value_input_dialog.dart';

class EditCourseTitleDialog extends StatelessWidget {
  final String currentTitle;

  const EditCourseTitleDialog({super.key, required this.currentTitle});

  @override
  Widget build(BuildContext context) {
    final libraryState = Provider.of<LibraryState>(context, listen: false);

    return ValueInputDialog(
      'Edit course title',
      currentTitle,
      'Course title',
      'OK',
      (value) {
        if (value == null || value.trim().length < 3) {
          return 'Title must be at least 3 characters';
        }
        if (libraryState.availableCourses.any((course) =>
            course.title.toLowerCase() == value.trim().toLowerCase() &&
            course.id != libraryState.selectedCourse?.id)) {
          return 'Course title already exists';
        }
        return null;
      },
      (newTitle) {
        libraryState.updateCourseTitle(newTitle.trim());
      },
    );
  }
}
