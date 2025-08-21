import 'package:flutter/material.dart';
import 'package:social_learning/data/session_plan_activity.dart';
import 'package:social_learning/data/session_play_activity_type.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/decomposed_course_designer_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/session_plan/select_lesson_for_activity_fanout_widget.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/session_plan/session_plan_context.dart';

class LessonActivityRow extends StatelessWidget {
  final SessionPlanActivity activity;
  final SessionPlanContext sessionPlanContext;
  final int reorderIndex;
  final LayerLink _layerLink = LayerLink();

  LessonActivityRow({
    super.key,
    required this.activity,
    required this.sessionPlanContext,
    required this.reorderIndex,
  });

  int _getDefaultDuration() {
    return sessionPlanContext
            .courseProfile?.defaultTeachableItemDurationInMinutes ??
        15;
  }

  String _durationText() {
    final defaultMinutes = _getDefaultDuration();
    if (activity.overrideDuration != null) {
      return '${activity.overrideDuration} min';
    } else {
      return '($defaultMinutes min)';
    }
  }

  TextStyle _durationStyle() {
    return TextStyle(
      fontSize: 13,
      color: activity.overrideDuration != null ? Colors.black : Colors.grey,
      fontStyle: activity.overrideDuration != null
          ? FontStyle.normal
          : FontStyle.italic,
    );
  }

  void _showDurationDialog(BuildContext context) async {
    final controller = TextEditingController(
      text: activity.overrideDuration?.toString() ?? '',
    );

    final result = await showDialog<int?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set Duration'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Duration in minutes',
              hintText: 'e.g. 10 or leave blank to reset',
            ),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) {
                  Navigator.of(context).pop(0); // signal to clear
                } else {
                  final value = int.tryParse(text);
                  Navigator.of(context).pop(value);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      await sessionPlanContext.updateActivityOverrideDuration(
        activityId: activity.id!,
        overrideDuration: result == 0 ? -1 : result,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lesson = sessionPlanContext.getLessonByActivity(activity);
    final time = sessionPlanContext.getStartTimeStringForActivity(activity);
    final color = SessionPlanActivityType.lesson.color;

    return DecomposedCourseDesignerCard.buildColorHighlightedBody(
      color: color,
      leadingText: time,
      dragHandleIndex: reorderIndex,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Lesson: ${lesson?.title ?? '(select a lesson)'}',
                style: const TextStyle(fontSize: 14),
              ),
            ),
            InkWell(
              onTap: () => _showDurationDialog(context),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
                child: Text(
                  _durationText(),
                  style: _durationStyle(),
                ),
              ),
            ),
            // const SizedBox(width: 8),
            Builder(
              builder: (iconContext) => CompositedTransformTarget(
                link: _layerLink,
                child: InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      SelectLessonForActivityFanoutWidget.show(
                        context: iconContext, // << use the icon's context
                        link: _layerLink,
                        activity: activity,
                        sessionPlanContext: sessionPlanContext,
                      );
                    });
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(Icons.edit, size: 20, color: Colors.grey),
                  ),
                ),
              ),
            ),
            // const SizedBox(width: 8),
            InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () {
                sessionPlanContext.deleteActivity(activity.id!);
              },
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(Icons.close, size: 20, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
