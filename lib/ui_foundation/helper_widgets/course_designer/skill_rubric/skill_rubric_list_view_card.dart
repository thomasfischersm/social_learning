import 'package:flutter/material.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/course_designer_card.dart';

class SkillRubricListViewCard extends StatelessWidget {
  const SkillRubricListViewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const CourseDesignerCard(
      title: 'Skill Rubric List',
      body: SizedBox.shrink(),
    );
  }
}
