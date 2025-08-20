import 'package:flutter/material.dart';
import 'package:percent_indicator/flutter_percent_indicator.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/session_plan/session_plan_context.dart';

import '../course_designer/course_designer_card.dart';

class SessionPlanOverviewCard extends StatelessWidget {
  final SessionPlanContext context;

  const SessionPlanOverviewCard({super.key, required this.context});

  @override
  Widget build(BuildContext context) {
    return CourseDesignerCard(
      title: "Step 7: Session Plan",
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Plan your session minute-by-minute with lessons and other classroom activities (e.g. opening circle, breaks, etc.)",
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: this.context.learningObjectives.map((objective) {
              final percent = this.context.getCompletionForObjective(objective);
              final isComplete = percent >= 1.0;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularPercentIndicator(
                    radius: 40.0,
                    lineWidth: 6.0,
                    percent: percent.clamp(0.0, 1.0),
                    center: Text("${(percent * 100).round()}%"),
                    progressColor: isComplete ? Colors.green : Colors.grey,
                    backgroundColor: Colors.grey.shade200,
                    circularStrokeCap: CircularStrokeCap.round,
                  ),
                  const SizedBox(height: 6),
                  ConstrainedBox(constraints: BoxConstraints(maxWidth: 92), child:
                  Text(
                    objective.name ?? "Untitled",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                    softWrap: true,

                  )),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
