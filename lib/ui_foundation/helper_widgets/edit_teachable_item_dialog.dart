import 'package:flutter/material.dart';
import 'package:social_learning/data/teachable_item.dart';
// LibraryState is no longer needed for direct Firestore operations
import 'package:social_learning/data/data_helpers/teachable_item_functions.dart'; // Added

class EditTeachableItemDialog extends StatefulWidget {
  final TeachableItem item;
  // LibraryState libraryState; // Removed

  const EditTeachableItemDialog({
    super.key,
    required this.item,
    // required this.libraryState, // Removed
  });

  @override
  State<EditTeachableItemDialog> createState() =>
      _EditTeachableItemDialogState();
}

class _EditTeachableItemDialogState extends State<EditTeachableItemDialog> {
  // No changes to controllers needed based on this refactor
  late TextEditingController _itemNameController;
  late TextEditingController _itemNotesController;

  @override
  void initState() {
    super.initState();
    _itemNameController = TextEditingController(text: widget.item.name);
    _itemNotesController = TextEditingController(text: widget.item.notes ?? '');
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _itemNotesController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final newName = _itemNameController.text.trim();
    final newNotes = _itemNotesController.text.trim();

    if (newName.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item name cannot be empty.')),
        );
      }
      return;
    }

    // Create a new TeachableItem with updated fields
    // Note: TeachableItem no longer has creatorId.
    // courseId, categoryId, sortOrder, tagIds, createdAt are not directly updated here.
    // TeachableItemFunctions.updateItem handles setting modifiedAt via server timestamp.
    // It primarily updates name and notes. If tagIds need update, it should be passed.
    
    // The TeachableItemFunctions.updateItem expects specific fields, not a full TeachableItem object.
    // However, to maintain consistency with how it might have been used or if other fields 
    // were intended to be updatable, we'll call it with the necessary fields.
    // The existing updateItem in TeachableItemFunctions takes:
    // itemId, name, notes, tagIds.

    try {
      await TeachableItemFunctions.updateItem(
        itemId: widget.item.id!, // Assuming item.id is non-null when editing
        name: newName,
        notes: newNotes.isNotEmpty ? newNotes : null,
        tagIds: widget.item.tagIds, // Pass existing tagIds, not modified here
      );
      if (mounted) {
        Navigator.of(context).pop(true); // Pop with true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating item: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _itemNameController,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _itemNotesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              textInputAction: TextInputAction.newline,
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop(); // Pop with false or null for no action
          },
        ),
        ElevatedButton(
          onPressed: _saveChanges,
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
}
