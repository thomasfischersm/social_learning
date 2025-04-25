// lib/ui_foundation/helper_widgets/student_checkoff_header_widget.dart

import 'package:flutter/material.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/profile_image_widget.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';

class InstructorClipboardHeaderWidget extends StatelessWidget {
  final User student;
  final int lessonsLearned;
  final int lessonsTaught;
  final LibraryState libraryState;

  const InstructorClipboardHeaderWidget({
    super.key,
    required this.student,
    required this.lessonsLearned,
    required this.lessonsTaught,
    required this.libraryState,
  });

  String _relativeSince(DateTime joined) {
    final diff = DateTime.now().difference(joined);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays < 7) return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''}';
    if (diff.inDays < 30) {
      final weeks = diff.inDays ~/ 7;
      return '$weeks week${weeks > 1 ? 's' : ''}';
    }
    if (diff.inDays < 365) {
      final months = diff.inDays ~/ 30;
      return '$months month${months > 1 ? 's' : ''}';
    }
    final years = diff.inDays ~/ 365;
    return '$years year${years > 1 ? 's' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final course = libraryState.selectedCourse;
    final prof = course != null
        ? student.getCourseProficiency(course)?.proficiency ?? 0
        : 0.0;
    final progressPct = (prof * 100).round();
    final since = _relativeSince(student.created.toDate());
    final bodyStyle = CustomTextStyles.getBody(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ProfileImageWidget(
                    student,
                    context,
                    maxRadius: 32,
                    linkToOtherProfile: true,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      student.displayName,
                      style: CustomTextStyles.headline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _statColumn('Since', since, bodyStyle)),
                  Expanded(child: _statColumn('Learned', '$lessonsLearned', bodyStyle)),
                  Expanded(child: _statColumn('Taught', '$lessonsTaught', bodyStyle)),
                  Expanded(child: _statColumn('Progress', '$progressPct%', bodyStyle)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statColumn(String label, String value, TextStyle? style) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: style),
        const SizedBox(height: 4),
        Text(value, style: style),
      ],
    );
  }
}
