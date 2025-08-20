import 'package:flutter/material.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/course_designer_card.dart';

class LearningObjectivesOverviewCard extends StatelessWidget{
  const LearningObjectivesOverviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return CourseDesignerCard(title: 'Step 6: Learning Outcomes', body: Text('Map learning outcomes\n  → what (teachable item)\n    → how (lesson)\n\nExample:\nLearning Outcome: Play a simple chess game\n  Teachable item: Pawn rules\n    Lesson: Rule review with mentor\n    Lesson: Solve 5 tricky situations'));
  }
}