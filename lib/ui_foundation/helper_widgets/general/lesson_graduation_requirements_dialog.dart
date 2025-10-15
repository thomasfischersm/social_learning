import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/practice_record.dart';
import 'package:social_learning/state/student_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/dialog_utils.dart';

Future<void> showLessonGraduationRequirementsDialog(
  BuildContext context,
  Lesson lesson,
) {
  final StudentState studentState =
      Provider.of<StudentState>(context, listen: false);
  final List<String> graduationRequirements =
      lesson.graduationRequirements ?? const <String>[];

  final PracticeRecord? latestRecord =
      studentState.getLatestGraduationPracticeRecord(lesson);
  final List<bool>? requirementStatuses =
      latestRecord?.graduationRequirementsMet;

  final List<Widget> requirementWidgets = <Widget>[];
  final List<bool> normalizedStatuses = requirementStatuses ?? <bool>[];

  if (graduationRequirements.isEmpty) {
    requirementWidgets.add(
      const Text('This lesson does not have any graduation requirements.'),
    );
  } else {
    for (int index = 0; index < graduationRequirements.length; index++) {
      final bool isMet =
          index < normalizedStatuses.length ? normalizedStatuses[index] : false;
      requirementWidgets.add(
        CheckboxListTile(
          value: isMet,
          onChanged: null,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          title: Text(graduationRequirements[index]),
          visualDensity: VisualDensity.compact,
        ),
      );
    }
  }

  final Widget content = SingleChildScrollView(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: requirementWidgets,
    ),
  );

  return DialogUtils.showInfoDialogWithContent(
    context,
    '${lesson.title} graduation requirements',
    content,
  );
}
