import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/data_helpers/reference_helper.dart';
import 'package:flutter/material.dart';
import 'package:social_learning/data/data_helpers/teachable_item_functions.dart';
import 'package:social_learning/data/teachable_item.dart';
import 'package:social_learning/data/teachable_item_tag.dart';
import 'package:social_learning/state/course_designer_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/inventory_entry.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/item_note_dialog.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/tag_fanout_widget.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/tag_pill.dart';
import 'package:social_learning/ui_foundation/helper_widgets/dialog_utils.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';

class InventoryItemEntry extends InventoryEntry {
  TeachableItem item;
  final Future<void> Function(TeachableItem item)? onDelete;

  InventoryItemEntry(this.item, {this.onDelete});

  @override
  String get pageKey => 'item-${item.id!}';

  @override
  Widget buildWidget(
      BuildContext context, VoidCallback refresh, CourseDesignerState state, int index) {
    final allTags = state.tags;
    final assignedTagIds =
    (item.tagIds ?? []).map((ref) => ref.path).toSet();

    final assignedTags = allTags
        .where((tag) => assignedTagIds.contains(_getRefPath(tag)))
        .toList();

    final availableTags = allTags
        .where((tag) => !assignedTagIds.contains(_getRefPath(tag)))
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Colors.grey.shade300),
          right: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                Text(item.name ?? '(Unnamed)',
                    style: CustomTextStyles.getBody(context)),

          if (item.notes?.trim().isNotEmpty ?? false)
            _icon(context, Icons.notes, () {
              showDialog(
                context: context,
                builder: (_) => ItemNoteDialog(
                  item: item,
                  onSaved: refresh,
                  startInEditMode: false,
                  dataContext: state,
                ),
              );
            }),

          _icon(context, Icons.edit, () {
            showDialog(
              context: context,
              builder: (_) => ItemNoteDialog(
                item: item,
                onSaved: refresh,
                startInEditMode: true,
                dataContext: state,
              ),
            );
          }),

          if (onDelete != null)
            _icon(context, Icons.delete, () {
              DialogUtils.showConfirmationDialog(
                context,
                'Delete item?',
                'Are you sure you want to delete "${item.name}"?',
                    () async {
                  await onDelete!(item);
                  refresh();
                },
              );
            }),

                ...assignedTags.map((tag) => InkWell(
            onTap: () {
              DialogUtils.showConfirmationDialog(
                context,
                'Remove tag?',
                'Do you want to remove the tag "${tag.name}"?',
                    () async {
                  final tagRef = docRef('teachableItemTags', tag.id!);
                  await TeachableItemFunctions.removeItemTagFromItem(
                    itemId: item.id!,
                    tagRef: tagRef,
                  );

                  final updated = await TeachableItemFunctions.getItemById(item.id!);
                  if (updated != null) {
                    item= updated; // Update local item reference
                    final index = state.items
                        .indexWhere((i) => i.id == item.id);
                    if (index != -1) {
                      state.items[index] = updated;
                    }
                  }

                  refresh();
                },
              );
            },
            child: TagPill(
              label: tag.name,
              color: _parseColor(tag.color),
            ),
          )),

                if (availableTags.isNotEmpty)
                  TagFanoutWidget(
              availableTags: availableTags,
              onTagSelected: (tag) async {
                final tagRef = docRef('teachableItemTags', tag.id!);

                await TeachableItemFunctions.assignTagToItem(
                  itemId: item.id!,
                  tagRef: tagRef,
                );

                final updated =
                await TeachableItemFunctions.getItemById(item.id!);
                if (updated != null) {
                  item= updated; // Update local item reference
                  final index = state.items
                      .indexWhere((i) => i.id == item.id);
                  if (index != -1) {
                    state.items[index] = updated;
                  }
                }

                refresh();
              },
                  ),
              ],
            ),
          ),
          ReorderableDragStartListener(
            index: index,
            child: const Icon(Icons.drag_handle, color: Colors.grey, size: 18),
          ),

        ],
      ),
    );
  }

  Widget _icon(BuildContext context, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: Icon(icon, size: 14, color: Colors.grey),
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xff')));
    } catch (_) {
      return Colors.grey;
    }
  }

  String _getRefPath(TeachableItemTag tag) =>
      docRef('teachableItemTags', tag.id!).path;
}
