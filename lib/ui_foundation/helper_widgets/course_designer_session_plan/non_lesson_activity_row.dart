import 'package:flutter/material.dart';
import 'package:social_learning/data/session_plan_activity.dart';
import 'package:social_learning/data/session_play_activity_type.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/decomposed_course_designer_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_session_plan/session_plan_context.dart';

class NonLessonActivityRow extends StatelessWidget {
  final SessionPlanActivity activity;
  final SessionPlanContext sessionPlanContext;

  const NonLessonActivityRow({
    super.key,
    required this.activity,
    required this.sessionPlanContext,
  });

  @override
  Widget build(BuildContext context) {
    final color = activity.activityType.color;
    final title = activity.name?.isNotEmpty == true ? activity.name! : '(enter name)';
    final startTime = sessionPlanContext.getStartTimeStringForActivity(activity);

    final overrideDuration = activity.overrideDuration;
    final defaultDuration = sessionPlanContext.courseProfile?.defaultTeachableItemDurationInMinutes ?? 15;
    final showDuration = overrideDuration ?? defaultDuration;
    final isOverride = overrideDuration != null;

    return DecomposedCourseDesignerCard.buildColorHighlightedBody(
      color: color,
      leadingText: startTime,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${activity.activityType.humanLabel}: $title',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: title == '(enter name)' ? FontStyle.italic : FontStyle.normal,
                  color: title == '(enter name)' ? Colors.grey : Colors.black,
                ),
              ),
            ),
            InkWell(
              onTap: () async {
                final controller = TextEditingController(
                  text: overrideDuration?.toString() ?? '',
                );

                final result = await showDialog<int?>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Edit duration'),
                    content: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Duration in minutes'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          final text = controller.text.trim();
                          if (text.isEmpty || int.tryParse(text) == 0) {
                            Navigator.pop(context, 0); // clear
                          } else {
                            Navigator.pop(context, int.tryParse(text));
                          }
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                );

                if (result != null) {
                  await sessionPlanContext.updateActivityOverrideDuration(
                    activityId: activity.id!,
                    overrideDuration: result == 0 ? null : result,
                  );
                }
              },
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  isOverride ? '$showDuration min' : '($defaultDuration min)',
                  style: TextStyle(
                    fontSize: 13,
                    color: isOverride ? Colors.black : Colors.grey,
                    fontStyle: isOverride ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ),
            ),
            InkWell(
              onTap: () async {
                final controller = TextEditingController(text: activity.name ?? '');
                final result = await showDialog<String>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Edit activity name'),
                    content: TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: const InputDecoration(hintText: 'Activity name'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, controller.text.trim()),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                );

                if (result != null && result != activity.name) {
                  await sessionPlanContext.updateActivity(
                    activityId: activity.id!,
                    name: result,
                  );
                }
              },
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(Icons.edit, size: 20, color: Colors.grey),
              ),
            ),

            InkWell(
              onTap: () => sessionPlanContext.deleteActivity(activity.id!),
              borderRadius: BorderRadius.circular(4),
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
