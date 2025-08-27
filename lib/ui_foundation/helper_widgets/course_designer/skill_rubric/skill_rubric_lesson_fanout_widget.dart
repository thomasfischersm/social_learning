import 'package:flutter/material.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/data/lesson.dart';

/// Shows an overlay menu to select a lesson from the library
/// excluding any lesson IDs in [excludeLessonIds]. When a lesson
/// is tapped, [onSelected] is invoked and the menu is dismissed.
class SkillRubricLessonFanoutWidget {
  static void show({
    required BuildContext context,
    required LayerLink link,
    required LibraryState libraryState,
    required Set<String> excludeLessonIds,
    required Future<void> Function(Lesson lesson) onSelected,
  }) {
    late OverlayEntry entry;

    void handleSelection(Lesson lesson) {
      entry.remove();
      onSelected(lesson);
    }

    entry = OverlayEntry(builder: (_) {
      final box = context.findRenderObject() as RenderBox;
      final origin = box.localToGlobal(Offset.zero);
      final size = box.size;
      final widgets = <Widget>[];

      for (final level in libraryState.levels ?? []) {
        final lessons = libraryState
            .getLessonsByLevel(level.id!)
            .where((l) => !excludeLessonIds.contains(l.id))
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
          widgets.add(
            InkWell(
              onTap: () => handleSelection(lesson),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text(lesson.title),
              ),
            ),
          );
        }
      }

      final unattached = libraryState
          .getUnattachedLessons()
          .where((l) => !excludeLessonIds.contains(l.id))
          .toList();
      if (unattached.isNotEmpty) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: const Text(
              'Other lessons',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
        );
        for (final lesson in unattached) {
          widgets.add(
            InkWell(
              onTap: () => handleSelection(lesson),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text(lesson.title),
              ),
            ),
          );
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
                  constraints:
                      const BoxConstraints(maxHeight: 300, minWidth: 180),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: widgets,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]),
      );
    });

    Overlay.of(context).insert(entry);
  }
}
