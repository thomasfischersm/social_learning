import 'package:flutter/material.dart';
import 'package:social_learning/data/session_play_activity_type.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/decomposed_course_designer_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_session_plan/session_plan_context.dart';

class AddActivityRow extends StatefulWidget {
  final SessionPlanContext sessionPlanContext;
  final String sessionPlanBlockId;

  const AddActivityRow({
    super.key,
    required this.sessionPlanContext,
    required this.sessionPlanBlockId,
  });

  @override
  State<AddActivityRow> createState() => _AddActivityRowState();
}

class _AddActivityRowState extends State<AddActivityRow> {
  SessionPlanActivityType _selectedType = SessionPlanActivityType.lesson;

  @override
  Widget build(BuildContext context) {
    final startTimeText = widget.sessionPlanContext
        .getStartTimeStringForNextActivity(widget.sessionPlanBlockId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecomposedCourseDesignerCard.buildColorHighlightedBody(
          color: _selectedType.color,
          leadingText: startTimeText,
          child: Row(
            children: [
              Expanded(
                child: DropdownButton<SessionPlanActivityType>(
                  value: _selectedType,
                  items: SessionPlanActivityType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.humanLabel),
                    );
                  }).toList(),
                  onChanged: (newType) {
                    if (newType != null) {
                      setState(() {
                        _selectedType = newType;
                      });
                    }
                  },
                ),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Add"),
                onPressed: () async {
                  await widget.sessionPlanContext.addActivity(
                    blockId: widget.sessionPlanBlockId,
                    activityType: _selectedType,
                  );
                },
              ),
            ],
          ),
        ),
        DecomposedCourseDesignerCard.buildFooter(),
        SizedBox(height: 16),
      ],
    );
  }
}
