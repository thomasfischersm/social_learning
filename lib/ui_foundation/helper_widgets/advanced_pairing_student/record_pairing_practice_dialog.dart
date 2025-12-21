import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/student_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/user_profile_widgets/profile_image_widget_v2.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';

class RecordPairingPracticeDialog extends StatefulWidget {
  final Lesson lesson;
  final User mentee;

  const RecordPairingPracticeDialog({
    super.key,
    required this.lesson,
    required this.mentee,
  });

  @override
  State<StatefulWidget> createState() => _RecordPairingPracticeDialogState();

  static void show(BuildContext context, Lesson lesson, User mentee) {
    showDialog(
      context: context,
      builder: (_) => RecordPairingPracticeDialog(
        lesson: lesson,
        mentee: mentee,
      ),
    );
  }
}

class _RecordPairingPracticeDialogState
    extends State<RecordPairingPracticeDialog> {
  bool _isReadyToGraduate = false;
  List<bool> _graduationRequirementsMet = [];

  @override
  void initState() {
    super.initState();

    if (widget.lesson.graduationRequirements != null) {
      _graduationRequirementsMet =
          List.filled(widget.lesson.graduationRequirements!.length, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Record Lesson'),
      scrollable: true,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _recordPressed, child: const Text('Record')),
      ],
      content: _buildContent(context),
    );
  }

  void _recordPressed() {
    Provider.of<StudentState>(context, listen: false).recordTeachingWithCheck(
        widget.lesson,
        widget.mentee,
        _isReadyToGraduate,
        _graduationRequirementsMet,
        context);
    Navigator.pop(context);
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomUiConstants.getTextPadding(Text(
            'Records that you taught a lesson.',
            style: CustomTextStyles.getBody(context))),
        Table(
          columnWidths: const {
            0: IntrinsicColumnWidth(),
            1: FlexColumnWidth()
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 4, 4),
                child: Text('Mentor:',
                    style: CustomTextStyles.getBody(context)),
              ),
              Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: ProfileImageWidgetV2.fromCurrentUser(),
                          ),
                        )),
                    Expanded(
                        flex: 3,
                        child: Text('You',
                            style: CustomTextStyles.getBody(context))),
                  ],
                ),
              ),
            ]),
            TableRow(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 4, 4),
                child: Text('Learner:',
                    style: CustomTextStyles.getBody(context)),
              ),
              Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: ProfileImageWidgetV2.fromUser(widget.mentee),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(widget.mentee.displayName,
                          style: CustomTextStyles.getBody(context)),
                    ),
                  ],
                ),
              ),
            ]),
          ],
        ),
        ..._generateGraduationRequirementsChecks(),
        ListTileTheme(
          horizontalTitleGap: 0,
          child: CheckboxListTile(
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            value: _isReadyToGraduate,
            onChanged: _checkGraduationRequirements()
                ? (value) {
                    setState(() {
                      _isReadyToGraduate = value ?? false;
                    });
                  }
                : null,
            title: Text('The learner is ready to teach this lesson.',
                style: CustomTextStyles.getBodyEmphasized(context)),
          ),
        ),
      ],
    );
  }

  List<Widget> _generateGraduationRequirementsChecks() {
    List<Widget> rows = [];
    var graduationRequirements = widget.lesson.graduationRequirements;
    if (graduationRequirements == null) {
      return rows;
    }

    for (String requirement in graduationRequirements) {
      var index = rows.length;
      rows.add(ListTileTheme(
          horizontalTitleGap: 0,
          child: CheckboxListTile(
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              title: Text(requirement, style: CustomTextStyles.getBody(context)),
              value: index < _graduationRequirementsMet.length
                  ? _graduationRequirementsMet[index]
                  : false,
              onChanged: (value) {
                setState(() {
                  _graduationRequirementsMet[index] = value ?? false;
                  _isReadyToGraduate =
                      _isReadyToGraduate && _checkGraduationRequirements();
                });
              })));
    }
    return rows;
  }

  bool _checkGraduationRequirements() {
    for (bool requirement in _graduationRequirementsMet) {
      if (!requirement) {
        return false;
      }
    }
    return true;
  }
}
