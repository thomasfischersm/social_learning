import 'package:flutter/material.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/session_plan/session_plan_context.dart';

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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade100,
                foregroundColor: Colors.black87,
                elevation: 0,
              ),
            ),
          ),

      ],
    );
  }
}
