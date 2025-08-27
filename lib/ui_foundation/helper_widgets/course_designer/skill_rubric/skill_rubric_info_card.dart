import 'package:flutter/material.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/course_designer_card.dart';

class SkillRubricInfoCard extends StatelessWidget {
  const SkillRubricInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const CourseDesignerCard(
      title: 'Step 5: Skill Rubric',
      body: Text(
          'Acquiring knowledge and developing skills are key to mastering '
          'a subject. Here, you can define the skills that develop a master. Each '
          'skill dimension can be broken into a degree of mastery. For each degree, '
          'you can list exercises (lessons) that help the student progress to the '
          'next degree.\n\n'
          'For example, pole dancing involves knowledge of moves and technique. '
          'It also requires developing skill in strength, flexibility, and '
          'body coordination. In a skill dimension like musicality, what a '
          'novice needs to develop to the next degree is different from what '
          'an advanced student needs.\n\n'
          'Plus: You\'ll be able to assess students based on the skills '
          'rubric. The app will generate a radar chart, which quickly '
          'communicates to you and the student where their '
          'strength/weaknesses are.'),
    );
  }
}
