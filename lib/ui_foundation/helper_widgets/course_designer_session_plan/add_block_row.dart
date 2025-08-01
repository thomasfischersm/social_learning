import 'package:flutter/material.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/decomposed_course_designer_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_session_plan/session_plan_context.dart';
import 'package:social_learning/ui_foundation/ui_constants/course_designer_theme.dart';

class AddBlockRow extends StatelessWidget {
  final SessionPlanContext sessionPlanContext;

  const AddBlockRow({super.key, required this.sessionPlanContext});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
            child: ElevatedButton.icon(
              onPressed: () {
                sessionPlanContext.addBlock(null);
              },
              icon: const Icon(Icons.add),
              label: const Text('Add New Block'),
              style: CourseDesignerTheme.secondaryButtonStyle,
            ),
          ),

      ],
    );
  }
}
