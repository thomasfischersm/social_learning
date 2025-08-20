import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/session_plan_activity.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/session_plan/session_plan_context.dart';
import 'package:social_learning/ui_foundation/ui_constants/course_designer_theme.dart';

class SelectLessonForActivityFanoutWidget {
  static void show({
    required BuildContext context,
    required LayerLink link,
    required SessionPlanActivity activity,
    required SessionPlanContext sessionPlanContext,
  }) {
    final libraryState = Provider.of<LibraryState>(context, listen: false);
    final currentLessonId = activity.lessonId?.id;

    final neededLessonIds = sessionPlanContext.getUnscheduledObjectiveLessonIds().toSet();

    late OverlayEntry entry;

    void _handleSelection(Lesson lesson) {
      entry.remove();
      sessionPlanContext.setLessonForActivity(
        activityId: activity.id!,
        lesson: lesson,
      );
    }

    entry = OverlayEntry(builder: (_) {
      final renderBox = context.findRenderObject() as RenderBox;
      final origin = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;

      final widgets = <Widget>[];

      for (final level in libraryState.levels ?? []) {
        final lessons = libraryState
            .getLessonsByLevel(level.id!)
            .where((l) => l.id != currentLessonId)
            .toList();

        if (lessons.isEmpty) continue;

        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              level.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
        );

        for (final lesson in lessons) {
          final needDot = neededLessonIds.contains(lesson.id);
          widgets.add(
            InkWell(
              onTap: () => _handleSelection(lesson),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text(
                    needDot ? '• ${lesson.title}' : lesson.title,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),
            ),
          );
        }
      }

      final unattached = libraryState
          .getUnattachedLessons()
          .where((l) => l.id != currentLessonId)
          .toList();

      if (unattached.isNotEmpty) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              'Other lessons',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
        );

        for (final lesson in unattached) {
          final needDot = neededLessonIds.contains(lesson.id);
          widgets.add(
            InkWell(
              onTap: () => _handleSelection(lesson),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text(
                    needDot ? '• ${lesson.title}' : lesson.title,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),
            ),
          );
        }
      }

      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => entry.remove(),
        child: Stack(
          children: [
            Positioned(
              left: origin.dx,
              top: origin.dy + size.height + 4,
              child: CompositedTransformFollower(
                link: link,
                offset: Offset(0, size.height + 4),
                showWhenUnlinked: false,
                child: Material(
                  elevation: 6,
                  borderRadius:
                      BorderRadius.circular(CourseDesignerTheme.cardBorderRadius),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 300,
                      minWidth: 200,
                      maxWidth: 320,
                    ),
                    child: IntrinsicWidth(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: widgets,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });

    Overlay.of(context)!.insert(entry);
  }
}
