import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/data_helpers/reference_helper.dart';
import 'package:social_learning/data/data_helpers/teachable_item_category_functions.dart';
import 'package:social_learning/data/data_helpers/teachable_item_functions.dart';
import 'package:social_learning/data/teachable_item.dart';
import 'package:social_learning/data/teachable_item_category.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/add_new_category_entry.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/add_new_item_entry.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/inventory_category_entry.dart';
import 'package:social_learning/state/course_designer_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/inventory_entry.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/inventory_item_entry.dart';

class InventoryDragHelper {
  static Future<void> handleReorder({
    required CourseDesignerState context,
    required List<InventoryEntry> inventoryEntries,
    required int oldIndex,
    required int newIndex,
  }) async {
    if (newIndex > oldIndex) newIndex -= 1;

    final dragged = inventoryEntries[oldIndex];
    final target = inventoryEntries[newIndex];

    if (dragged is InventoryItemEntry) {
      await _handleItemDrag(
        context: context,
        inventoryEntries: inventoryEntries,
        draggedEntry: dragged,
        newIndex: newIndex,
      );
    } else if (dragged is InventoryCategoryEntry) {
      await _handleCategoryDrag(
        context: context,
        inventoryEntries: inventoryEntries,
        draggedEntry: dragged,
        newIndex: newIndex,
      );
    }
  }

  static Future<void> _handleCategoryDrag({
    required CourseDesignerState context,
    required List<InventoryEntry> inventoryEntries,
    required InventoryCategoryEntry draggedEntry,
    required int newIndex,
  }) async {
    final draggedCategory = draggedEntry.category;

    int newSortOrder = 0;
    final target = inventoryEntries[newIndex];

    if (target is InventoryCategoryEntry) {
      newSortOrder = context.getCategories().indexWhere((c) => c.id == target.category.id);
    } else if (target is InventoryItemEntry || target is AddNewItemEntry) {
      final targetCategoryId = target is InventoryItemEntry
          ? target.item.categoryId.id
          : (target as AddNewItemEntry).category.id;

      final targetIndex =
      context.getCategories().indexWhere((c) => c.id == targetCategoryId);
      newSortOrder = targetIndex + 1;
    } else if (target is AddNewCategoryEntry) {
      newSortOrder = context.getCategories().length - 1;
    } else {
      return;
    }

    await TeachableItemCategoryFunctions.updateCategorySortOrder(
      movedCategory: draggedCategory,
      newIndex: newSortOrder,
      allCategoriesForCourse: context.getCategories(),
    );
  }

  static Future<void> _handleItemDrag({
    required CourseDesignerState context,
    required List<InventoryEntry> inventoryEntries,
    required InventoryItemEntry draggedEntry,
    required int newIndex,
  }) async {
    final draggedItem = draggedEntry.item;
    final allItems = context.getItems();
    final target = inventoryEntries[newIndex];

    DocumentReference newCategoryRef;
    int newIndexInCategory = 0;

    if (target is InventoryItemEntry) {
      newCategoryRef = target.item.categoryId;

      final itemsInCategory = context
          .getItemsForCategory(newCategoryRef.id!)
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      newIndexInCategory = itemsInCategory.indexWhere((i) => i.id == target.item.id);
    } else if (target is AddNewItemEntry) {
      newCategoryRef = docRef('teachableItemCategories', target.category.id!);

      final itemsInCategory = context.getItemsForCategory(target.category.id!);
      newIndexInCategory = itemsInCategory.length;
    } else if (target is InventoryCategoryEntry) {
      newCategoryRef = docRef('teachableItemCategories', target.category.id!);
      newIndexInCategory = 0;
    } else if (target is AddNewCategoryEntry) {
      final lastCategory = (context.getCategories()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)))
          .last;

      newCategoryRef = docRef('teachableItemCategories', lastCategory.id!);

      final itemsInCategory = context.getItemsForCategory(lastCategory.id!);
      newIndexInCategory = itemsInCategory.length;
    } else {
      return;
    }

    await TeachableItemFunctions.updateItemSortOrder(
      allItemsAcrossCategories: allItems,
      movedItem: draggedItem,
      newCategoryRef: newCategoryRef,
      newIndex: newIndexInCategory,
    );
  }
}
