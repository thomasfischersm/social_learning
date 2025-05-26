import 'package:flutter/material.dart';
import 'package:social_learning/data/data_helpers/teachable_item_functions.dart';
import 'package:social_learning/data/teachable_item.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/inventory_context.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/inventory_entry.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/item_note_dialog.dart';
import 'package:social_learning/ui_foundation/helper_widgets/dialog_utils.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';

class InventoryItemEntry extends InventoryEntry {
  final TeachableItem item;
  final Future<void> Function(TeachableItem item)? onDelete;

  InventoryItemEntry(this.item, {this.onDelete});

  @override
  Widget buildWidget(BuildContext context, VoidCallback refresh, InventoryContext dataContext) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Colors.grey.shade300),
          right: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
        child: Row(
          children: [
            // Item name
            Text(item.name ?? '(Unnamed)', style: CustomTextStyles.getBody(context)),

            // 📝 Note icon (if note exists)
            if (item.notes != null && item.notes!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 6.0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(4),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => ItemNoteDialog(
                          item: item,
                          onSaved: refresh,
                          startInEditMode: false,
                          dataContext: dataContext,
                        ),
                      );
                    },
                    child: Icon(Icons.notes, size: 14, color: Colors.grey[500]),
                  ),
                ),
              ),

            // ✏️ Edit icon
            Padding(
              padding: const EdgeInsets.only(left: 6.0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => ItemNoteDialog(
                        item: item,
                        onSaved: refresh,
                        startInEditMode: true,
                        dataContext: dataContext,
                      ),
                    );
                  },
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
                        'Delete item?',
                        'Are you sure you want to delete "${item.name}"?',
                            () async {
                          await onDelete!(item);
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
}
