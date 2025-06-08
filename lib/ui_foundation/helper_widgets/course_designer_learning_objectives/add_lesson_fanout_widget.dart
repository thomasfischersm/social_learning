import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/teachable_item.dart';
import 'package:social_learning/data/learning_objective.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_learning_objectives/learning_objectives_context.dart';

class AddLessonFanoutWidget {
  static void show({
    required BuildContext context,
    required LayerLink link,
    required TeachableItem item,
    required Lesson currentLesson,
    required LearningObjectivesContext objectivesContext,
  }) {
    final library = Provider.of<LibraryState>(context, listen: false);

    // Build a set of already-attached lesson IDs (minus the one we're replacing)
    final attachedIds = (item.lessonRefs ?? [])
        .map((ref) => ref.id)
        .whereType<String>()
        .toSet()
      ..remove(currentLesson.id);

    late OverlayEntry entry;
    entry = OverlayEntry(builder: (_) {
      final box = context.findRenderObject() as RenderBox;
      final origin = box.localToGlobal(Offset.zero);
      final size = box.size;

      // Build menu items: grouped by level, then unattached
      final widgets = <Widget>[];

      // 1) Lessons grouped by each level
      for (final level in library.levels ?? []) {
        final lessons = library.getLessonsByLevel(level.id!)
            .where((l) => !attachedIds.contains(l.id))
            .toList();
        if (lessons.isEmpty) continue;

        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            level.title,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ));

        for (final lesson in lessons) {
          widgets.add(InkWell(
            onTap: () {
              entry.remove();
              objectivesContext.replaceLessonForTeachableItem(
                item: item,
                oldLesson: currentLesson,
                newLesson: lesson,
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(lesson.title),
            ),
          ));
        }
      }

      // 2) Unattached lessons
      final unattached = library.getUnattachedLessons()
          .where((l) => !attachedIds.contains(l.id))
          .toList();
      if (unattached.isNotEmpty) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            'Unattached',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ));
        for (final lesson in unattached) {
          widgets.add(InkWell(
            onTap: () {
              entry.remove();
              objectivesContext.replaceLessonForTeachableItem(
                item: item,
                oldLesson: currentLesson,
                newLesson: lesson,
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(lesson.title),
            ),
          ));
        }
      }

      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => entry.remove(),
        child: Stack(children: [
          Positioned(
            left: origin.dx,
            top: origin.dy + size.height + 4,
            child: CompositedTransformFollower(
              link: link,
              offset: Offset(0, size.height + 4),
              showWhenUnlinked: false,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 300, minWidth: 180),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: widgets),
                  ),
                ),
              ),
            ),
          ),
        ]),
      );
    });

    Overlay.of(context)!.insert(entry);
  }
}
