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

    var children = [
      for (final block in blocks) ...[
        SessionBlockHeaderRow(
          key: ValueKey('block_${block.id}'),
          block: block,
          contextData: sessionPlanContext,
        ),

        for (final activity in sessionPlanContext.getActivitiesForBlock(block.id!))
          if (activity.activityType == SessionPlanActivityType.lesson)
            LessonActivityRow(
              key: ValueKey('activity_${activity.id}'),
              activity: activity,
              sessionPlanContext: sessionPlanContext,
            )
          else
            NonLessonActivityRow(
              key: ValueKey('activity_${activity.id}'),
              activity: activity,
              sessionPlanContext: sessionPlanContext,
            ),

        AddActivityRow(
          key: ValueKey('add_activity_${block.id}'),
          sessionPlanBlockId: block.id!,
          sessionPlanContext: sessionPlanContext,
        )
      ],

      AddBlockRow(
          key: ValueKey('add_block'),
          sessionPlanContext: sessionPlanContext),
    ];

    final keys = children.map((e) => (e.key as ValueKey).value as String).toList();

    // return ReorderableListView.builder(
    //   buildDefaultDragHandles: false,
    //   padding: EdgeInsets.zero,
    //   onReorder: (fromIndex, toIndex) => _handleReorder(keys[fromIndex], keys[toIndex]),
    //   children: children,
    // );

    return ReorderableListView.builder(
      buildDefaultDragHandles: false,        // <- turn off auto handle
      itemCount: children.length,
      itemBuilder: (context, index) {
        final child = children[index];

        return ReorderableDragStartListener(
          key: child.key,
          index: index,                      // index of the item
          child: child
        );
      },
      onReorder: (fromIndex, toIndex) => _handleReorder(keys[fromIndex], keys[toIndex]),
    );

  }

  void _handleReorder(String fromKey, String toKey) {
    if (_isAddBlock(fromKey) || _isAddActivity(fromKey)) return;

    if (_isBlock(fromKey)) {
      if (_isBlock(toKey)) {
        _handleBlockToBlock(fromKey, toKey);
      } else if (_isActivity(toKey)) {
        _handleBlockToActivity(fromKey, toKey);
      } else if (_isAddBlock(toKey)) {
        _handleBlockToEnd(fromKey);
      } else if (_isAddActivity(toKey)) {
        _handleBlockToActivity(fromKey, toKey);
      }
    } else if (_isActivity(fromKey)) {
      if (_isBlock(toKey)) {
        _handleActivityToBlock(fromKey, toKey);
      } else if (_isActivity(toKey)) {
        _handleActivityToActivity(fromKey, toKey);
      } else if (_isAddBlock(toKey)) {
        _handleActivityToEndOfLastBlock(fromKey);
      } else if (_isAddActivity(toKey)) {
        _handleActivityToAddActivity(fromKey, toKey);
      }
    }
  }

  /* ───────────────────────── block handlers ───────────────────────── */

  void _handleBlockToBlock(String fromKey, String toKey) {
    final fromId = fromKey.substring('block_'.length);
    final beforeId = toKey.substring('block_'.length);
    if (fromId == beforeId) return;
    sessionPlanContext.moveBlockBefore(
      fromBlockId: fromId,
      beforeBlockId: beforeId,
    );
  }

  void _handleBlockToActivity(String fromKey, String toKey) {
    final fromId = fromKey.substring('block_'.length);

    // Destination block is the block that owns the activity / add-activity row
    final destBlockId = _isActivity(toKey)
        ? sessionPlanContext
        .activityById[toKey.substring('activity_'.length)]!
        .sessionPlanBlockId
        .id
        : toKey.substring('add_activity_'.length);

    sessionPlanContext.moveBlockBefore(
      fromBlockId: fromId,
      beforeBlockId: destBlockId,
    );
  }

  void _handleBlockToEnd(String fromKey) {
    final fromId = fromKey.substring('block_'.length);
    sessionPlanContext.moveBlockBefore(fromBlockId: fromId, beforeBlockId: null);
  }

  /* ───────────────────────── activity handlers ───────────────────────── */

  void _handleActivityToBlock(String fromKey, String toKey) {
    final activityId = fromKey.substring('activity_'.length);
    final activity = sessionPlanContext.activityById[activityId];

    final fromBlockId = activity!.sessionPlanBlockId.id;
    final toBlockId = toKey.substring('block_'.length);

    // Place BEFORE the first activity of destination block (or last if none)
    final destActivities =
    sessionPlanContext.getActivitiesForBlock(toBlockId);
    final beforeId = destActivities.isNotEmpty ? destActivities.first.id : null;

    sessionPlanContext.moveActivity3(
      activityId: activityId,
      fromBlockId: fromBlockId,
      toBlockId: toBlockId,
      beforeActivityId: beforeId,
    );
  }

  void _handleActivityToActivity(String fromKey, String toKey) {
    final activityId = fromKey.substring('activity_'.length);
    final targetId = toKey.substring('activity_'.length);
    if (activityId == targetId) return;

    final source = sessionPlanContext.activityById[activityId];
    final fromBlockId = source!.sessionPlanBlockId.id;

    final target = sessionPlanContext.activityById[targetId];
    final toBlockId = target!.sessionPlanBlockId.id;

    sessionPlanContext.moveActivity3(
      activityId: activityId,
      fromBlockId: fromBlockId,
      toBlockId: toBlockId,
      beforeActivityId: targetId,
    );
  }

  void _handleActivityToEndOfLastBlock(String fromKey) {
    final activityId = fromKey.substring('activity_'.length);
    final activity = sessionPlanContext.activityById[activityId];

    final fromBlockId = activity!.sessionPlanBlockId!.id;
    final lastBlockId = sessionPlanContext.blocks.last.id!;

    sessionPlanContext.moveActivity3(
      activityId: activityId,
      fromBlockId: fromBlockId,
      toBlockId: lastBlockId,
      beforeActivityId: null,
    );
  }

  void _handleActivityToAddActivity(String fromKey, String toKey) {
    final activityId = fromKey.substring('activity_'.length);
    final destBlockId = toKey.substring('add_activity_'.length);

    final source = sessionPlanContext.activityById[activityId];
    final fromBlockId = source!.sessionPlanBlockId!.id;

    sessionPlanContext.moveActivity3(
      activityId: activityId,
      fromBlockId: fromBlockId,
      toBlockId: destBlockId,
      beforeActivityId: null,
    );
  }



  bool _isBlock(String key) => key.startsWith('block_');
  bool _isActivity(String key) => key.startsWith('activity_');
  bool _isAddActivity(String key) => key.startsWith('add_activity_');
  bool _isAddBlock(String key) => key == 'add_block';

}
