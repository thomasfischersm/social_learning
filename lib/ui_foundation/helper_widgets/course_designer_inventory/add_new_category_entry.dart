import 'package:flutter/material.dart';
import 'package:social_learning/ui_foundation/course_designer_inventory_page.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/inventory_context.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/inventory_entry.dart';

class AddNewCategoryEntry extends InventoryEntry {
  final Future<void> Function(String name) onAdd;
  final InventoryContext contextData;

  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();

  AddNewCategoryEntry({
    required this.onAdd,
    required this.contextData,
  });

  @override
  Widget buildWidget(BuildContext context, VoidCallback refresh, InventoryContext _) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          labelText: 'Add new category...',
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
          ),
        ),
        onSubmitted: (text) async {
          final trimmed = text.trim();
          if (trimmed.isEmpty) return;

          final duplicate = contextData
              .getCategories()
              .any((c) => c.name.toLowerCase().trim() == trimmed.toLowerCase());

          if (duplicate) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('A category with that name already exists.')),
            );
            return;
          }

          controller.clear();
          final currentFocus = focusNode;
          await onAdd(trimmed);
          Future.delayed(const Duration(milliseconds: 100), () {
            if (!currentFocus.hasFocus) {
              FocusScope.of(context).requestFocus(currentFocus);
            }
          });
          refresh();
        },
      ),
    );
  }
}
