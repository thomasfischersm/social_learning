import 'package:flutter/material.dart';
import 'package:social_learning/data/teachable_item_category.dart';
import 'package:social_learning/state/course_designer_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/inventory_entry.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/ui_constants/course_designer_theme.dart';

class AddNewItemEntry extends InventoryEntry {
  final TeachableItemCategory category;
  final Future<void> Function(TeachableItemCategory category, String name) onAdd;
  final CourseDesignerState state;

  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();

  AddNewItemEntry({
    required this.category,
    required this.onAdd,
    required this.state,
  });

  @override
  Widget buildWidget(BuildContext context, VoidCallback refresh, CourseDesignerState _) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: CourseDesignerTheme.cardBorderColor),
          right: BorderSide(color: CourseDesignerTheme.cardBorderColor),
          bottom: BorderSide(color: CourseDesignerTheme.cardBorderColor),
        ),
        borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(CourseDesignerTheme.cardBorderRadius)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          style: CustomTextStyles.getBody(context),
          decoration: CustomUiConstants.getFilledInputDecoration(
            context,
            labelText: 'New item',
            enabledColor: Colors.grey.shade300,
          ),
          onSubmitted: (text) async {
            final trimmed = text.trim();
            if (trimmed.isEmpty) return;

            final duplicate = state
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
                focusNode.requestFocus();
              }
            });
            refresh();
          },
        ),
      ),
    );
  }
}
