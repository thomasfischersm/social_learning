import 'package:flutter/material.dart';
import 'package:social_learning/data/data_helpers/teachable_item_category_functions.dart';
import 'package:social_learning/data/teachable_item_category.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/inventory_context.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/inventory_entry.dart';
import 'package:social_learning/ui_foundation/helper_widgets/dialog_utils.dart';
import 'package:social_learning/ui_foundation/helper_widgets/value_input_dialog.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';

class InventoryCategoryEntry extends InventoryEntry {
  final TeachableItemCategory category;
  bool isExpanded;
  final Future<void> Function(TeachableItemCategory category)? onDelete;
  final InventoryContext contextData;

  InventoryCategoryEntry(
      this.category, {
        this.isExpanded = true,
        this.onDelete,
        required this.contextData,
      });

  @override
  Widget buildWidget(BuildContext context, VoidCallback refresh, InventoryContext _) {
    return Container(
      margin: const EdgeInsets.only(top: 12.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        child: Row(
          children: [
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
                    child: const Icon(Icons.delete, size: 14, color: Colors.grey),
                  ),
                ),
              ),

            const Spacer(),
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

          final isDuplicate = contextData
              .getCategories()
              .any((c) => c.id != category.id && c.name.toLowerCase().trim() == trimmed);

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
