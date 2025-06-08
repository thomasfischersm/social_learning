import 'package:flutter/material.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/course_designer_card.dart';

class LearningObjectivesOverviewCard extends StatelessWidget{
  const LearningObjectivesOverviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return CourseDesignerCard(title: 'Learning Outcomes', body: Text('Think about what you want students to walk away with and work backwards on how to get them there.'));
  }
}