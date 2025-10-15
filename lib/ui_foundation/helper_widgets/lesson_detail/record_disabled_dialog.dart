import 'package:flutter/material.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';

class RecordDisabledDialog extends StatelessWidget {
  const RecordDisabledDialog({super.key});

  static void showDisabledDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => RecordDisabledDialog());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Graduate student"),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text("OK"),
        ),
      ],
      content: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            'Once you\'ve mastered this lesson, you will be able to record '
            'that you taught someone here.\n\n'
            'For now, find an instructor or '
            'student to practice this lesson with. They will be able to record '
            'it for you.\n',
            style: CustomTextStyles.getBodyEmphasized(context)),
        Text(
            'Note: There is a difference between having done something once '
            'and being actually proficient at it. Take riding a bicycle '
            'for example. Once you\'ve been able to push off for a couple '
            'yards, you\'ve been riding your bicycle but you are not '
            'proficient yet. Similarly, having done this lesson once is '
            'not the same as having fully learned it.\n\n'
            'Having to graduate a lesson may feel like being held back when '
            'one wants to storm forward. However, a solid foundation is going '
            'to serve you better in the long run. Plus, it\'ll ensure '
            'quality for students learning from other students.\n'
            'However, being held back from graduating shouldn\'t be an '
            'eternal "not yet." Your instructor or mentoring student '
            'should give you specific feedback on what you need to do to '
            'master it.',
            style: CustomTextStyles.getBodyNote(context)),
      ],
    );
  }
}
