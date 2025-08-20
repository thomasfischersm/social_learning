import 'package:flutter/material.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/course_designer_card.dart';

class SkillRubricInfoCard extends StatelessWidget {
  const SkillRubricInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const CourseDesignerCard(
      title: 'Step 5: Skill Rubric',
      body: SizedBox.shrink(),
    );
  }
}
