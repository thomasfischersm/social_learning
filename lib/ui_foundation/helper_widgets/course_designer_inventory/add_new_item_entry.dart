import 'package:flutter/material.dart';
import 'package:social_learning/data/teachable_item_category.dart';
import 'package:social_learning/ui_foundation/course_designer_inventory_page.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/inventory_context.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/inventory_entry.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';

class AddNewItemEntry extends InventoryEntry {
  final TeachableItemCategory category;
  final Future<void> Function(TeachableItemCategory category, String name) onAdd;
  final InventoryContext contextData;

  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();

  AddNewItemEntry({
    required this.category,
    required this.onAdd,
    required this.contextData,
  });

  @override
  Widget buildWidget(BuildContext context, VoidCallback refresh, InventoryContext _) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Colors.grey.shade300),
          right: BorderSide(color: Colors.grey.shade300),
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          style: CustomTextStyles.getBody(context),
          decoration: InputDecoration(
            labelText: 'New item',
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
            ),
          ),
          onSubmitted: (text) async {
            final trimmed = text.trim();
            if (trimmed.isEmpty) return;

            final duplicate = contextData
                .getItemsForCategory(category.id!)
                .any((item) => (item.name ?? '').toLowerCase().trim() == trimmed.toLowerCase());

            if (duplicate) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('An item with that name already exists in this category.')),
              );
              return;
            }

            controller.clear();
            final currentFocus = focusNode;
            await onAdd(category, trimmed);
            Future.delayed(const Duration(milliseconds: 100), () {
              if (!currentFocus.hasFocus) {
                FocusScope.of(context).requestFocus(currentFocus);
              }
            });
            refresh();
          },
        ),
      ),
    );
  }
}
