import 'package:flutter/material.dart';
import 'package:social_learning/data/data_helpers/teachable_item_category_functions.dart';
import 'package:social_learning/data/teachable_item_category.dart';
import 'package:social_learning/state/course_designer_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/inventory_entry.dart';
import 'package:social_learning/ui_foundation/helper_widgets/dialog_utils.dart';
import 'package:social_learning/ui_foundation/helper_widgets/value_input_dialog.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/course_designer_theme.dart';

class InventoryCategoryEntry extends InventoryEntry {
  final TeachableItemCategory category;
  bool isExpanded;
  final Future<void> Function(TeachableItemCategory category)? onDelete;
  final CourseDesignerState state;

  InventoryCategoryEntry(
    this.category, {
    this.isExpanded = true,
    this.onDelete,
    required this.state,
  });

  @override
  String get pageKey => 'category-${category.id!}';

  @override
  Widget buildWidget(BuildContext context, VoidCallback refresh,
      CourseDesignerState _, int index) {
    return Container(
      margin: CourseDesignerTheme.cardMargin,
      decoration: BoxDecoration(
        color: CourseDesignerTheme.cardHeaderBackgroundColor,
        border: Border.all(color: CourseDesignerTheme.cardBorderColor),
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(CourseDesignerTheme.cardBorderRadius)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Row(
          children: [
            const SizedBox(width: 4),
            // Expand/collapse icon with ripple
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: () {
                    isExpanded = !isExpanded;
                    refresh();
                  },
                  child: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ),

            // Category name
            Text(
              category.name,
              style: CustomTextStyles.subHeadline,
            ),

            // ✏️ Edit icon
            Padding(
              padding: const EdgeInsets.only(left: 6.0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: () => _editCategoryName(context, refresh),
                  child: const Icon(Icons.edit, size: 14, color: Colors.grey),
                ),
              ),
            ),

            // 🗑 Delete icon
            if (onDelete != null)
              Padding(
                padding: const EdgeInsets.only(left: 6.0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(4),
                    onTap: () {
                      DialogUtils.showConfirmationDialog(
                        context,
                        'Delete category?',
                        'Are you sure you want to delete the category "${category.name}" and all its items?',
                        () async {
                          await onDelete!(category);
                          refresh();
                        },
                      );
                    },
                    child:
                        const Icon(Icons.delete, size: 14, color: Colors.grey),
                  ),
                ),
              ),

            const Spacer(),
            // Drag handle
            ReorderableDragStartListener(
              index: index,
              child:
                  const Icon(Icons.drag_handle, color: Colors.grey, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  void _editCategoryName(BuildContext context, VoidCallback refresh) {
    showDialog(
      context: context,
      builder: (_) => ValueInputDialog(
        'Edit Category Name',
        category.name,
        'Enter new name',
        'Save',
        (val) {
          final trimmed = val?.trim().toLowerCase() ?? '';
          if (trimmed.isEmpty) {
            return 'Name cannot be empty';
          }

          final isDuplicate = state.categories.any((c) =>
              c.id != category.id && c.name.toLowerCase().trim() == trimmed);

          if (isDuplicate) {
            return 'Another category with this name already exists.';
          }

          return null;
        },
        (newName) async {
          await TeachableItemCategoryFunctions.updateCategory(
            categoryId: category.id!,
            name: newName,
          );
          category.name = newName;
          refresh();
        },
      ),
    );
  }
}
