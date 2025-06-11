import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/teachable_item.dart';
import 'package:social_learning/data/learning_objective.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_learning_objectives/learning_objectives_context.dart';

class AddTeachableItemFanoutWidget {
  /// Shows an overlay menu of all teachable items grouped by category.
  /// If [currentItem] is non-null, selecting an item will replace it;
  /// otherwise it will add a new teachable item to the objective.
  static void show({
    required BuildContext context,
    required LayerLink link,
    required LearningObjective objective,
    required LearningObjectivesContext objectivesContext,
    TeachableItem? currentItem,
  }) {
    // Build set of already-assigned teachableItem IDs, minus the one being replaced
    final assignedIds = objective.teachableItemRefs
        .map((ref) => ref.id!)
        .toSet();
    if (currentItem != null) assignedIds.remove(currentItem.id);

    // Get sorted categories from the context
    final categories = objectivesContext.categories.toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    late OverlayEntry entry;

    // Common selection handler
    void _handleSelection(TeachableItem item) {
      entry.remove();
      if (currentItem != null) {
        objectivesContext.replaceTeachableItemInObjective(
          objective: objective,
          oldItem: currentItem,
          newItem: item,
        );
      } else {
        objectivesContext.addTeachableItemToObjective(
          objective: objective,
          item: item,
        );
      }
    }

    entry = OverlayEntry(builder: (_) {
      // Position of the icon
      final box = context.findRenderObject() as RenderBox;
      final origin = box.localToGlobal(Offset.zero);
      final size = box.size;

      // Build the menu items
      final menuItems = <Widget>[];
      for (final category in categories) {
        final items = objectivesContext.getTeachableItemsForCategory(category.id!);
        final available = items.where((i) => !assignedIds.contains(i.id)).toList();
        if (available.isEmpty) continue;

        // Category header
        menuItems.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              category.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
        );

        // Each available item
        for (final item in available) {
          menuItems.add(
            InkWell(
              onTap: () => _handleSelection(item),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text(item.name ?? '(Untitled)'),
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
                      children: menuItems,
                    ),
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
