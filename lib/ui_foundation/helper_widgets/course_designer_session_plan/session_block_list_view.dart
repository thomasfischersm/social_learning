import 'package:flutter/material.dart';
import 'package:social_learning/data/session_plan_activity.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_session_plan/add_activity_row.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_session_plan/add_block_row.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_session_plan/lesson_activity_row.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_session_plan/non_lesson_activity_row.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_session_plan/session_block_header_row.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_session_plan/session_plan_context.dart';
import 'package:social_learning/data/session_play_activity_type.dart';

class SessionBlocksListView extends StatelessWidget {
  final SessionPlanContext sessionPlanContext;

  const SessionBlocksListView({super.key, required this.sessionPlanContext});

  @override
  Widget build(BuildContext context) {
    final blocks = sessionPlanContext.blocks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final block in blocks) ...[
          SessionBlockHeaderRow(
            block: block,
            contextData: sessionPlanContext,
          ),

          for (final activity in sessionPlanContext.getActivitiesForBlock(block.id!))
            if (activity.activityType == SessionPlanActivityType.lesson)
              LessonActivityRow(
                activity: activity,
                sessionPlanContext: sessionPlanContext,
              )
            else
              NonLessonActivityRow(
                activity: activity,
                sessionPlanContext: sessionPlanContext,
              ),

          AddActivityRow(
            sessionPlanBlockId: block.id!,
            sessionPlanContext: sessionPlanContext,
          ),
        ],

        AddBlockRow(sessionPlanContext: sessionPlanContext),
      ],
    );
  }
}
