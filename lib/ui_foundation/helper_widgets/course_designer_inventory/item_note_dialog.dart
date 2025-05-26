import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:social_learning/data/data_helpers/teachable_item_functions.dart';
import 'package:social_learning/data/teachable_item.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/inventory_context.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ItemNoteDialog extends StatefulWidget {
  final TeachableItem item;
  final VoidCallback onSaved;
  final bool startInEditMode;
  final InventoryContext dataContext;

  const ItemNoteDialog({
    super.key,
    required this.item,
    required this.onSaved,
    required this.dataContext,
    this.startInEditMode = false,
  });

  @override
  State<ItemNoteDialog> createState() => _ItemNoteDialogState();
}

class _ItemNoteDialogState extends State<ItemNoteDialog> {
  late bool isEditing;
  late TextEditingController nameController;
  late TextEditingController noteController;

  @override
  void initState() {
    super.initState();
    isEditing = widget.startInEditMode;
    nameController = TextEditingController(text: widget.item.name ?? '');
    noteController = TextEditingController(text: widget.item.notes ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: isEditing
          ? const Text('Edit Item')
          : Text(widget.item.name ?? '(Unnamed)'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 400, maxWidth: 500),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: isEditing ? _buildEditContent() : _buildPreviewContent(),
          ),
        ),
      ),
      actions: [
        if (!isEditing)
          TextButton(
            onPressed: () => setState(() => isEditing = true),
            child: const Text('Edit'),
          ),
        if (isEditing)
          ElevatedButton(
            onPressed: _saveItem,
            child: const Text('Save'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Future<void> _saveItem() async {
    final name = nameController.text.trim();
    final note = noteController.text.trim();

    if (name.isEmpty) {
      _showError('Name cannot be empty');
      return;
    }

    final existingItems = widget.dataContext
        .getItems()
        .where((item) =>
    item.categoryId.id == widget.item.categoryId.id &&
        item.id != widget.item.id &&
        (item.name?.toLowerCase().trim() == name.toLowerCase()))
        .toList();

    if (existingItems.isNotEmpty) {
      _showError('Another item with this name already exists in this category.');
      return;
    }

    await TeachableItemFunctions.updateItem(
      itemId: widget.item.id!,
      name: name,
      notes: note.isEmpty ? null : note,
    );

    widget.item.name = name;
    widget.item.notes = note.isEmpty ? null : note;
    widget.onSaved();

    Navigator.of(context).pop();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  List<Widget> _buildEditContent() {
    return [
      TextFormField(
        controller: nameController,
        decoration: InputDecoration(
          labelText: 'Item name',
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: noteController,
        decoration: InputDecoration(
          labelText: 'Notes',
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        maxLines: null,
        minLines: 5,
        keyboardType: TextInputType.multiline,
      ),
    ];
  }

  List<Widget> _buildPreviewContent() {
    final spans = _parseNoteWithLinks(widget.item.notes ?? '');
    return [
      if (spans.isEmpty)
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('No notes available.'),
        )
      else
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: SelectableText.rich(
              TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: spans,
              ),
            ),
          ),
        ),
    ];
  }

  List<TextSpan> _parseNoteWithLinks(String text) {
    final RegExp urlRegex = RegExp(r'(https?:\/\/[^\s]+)');
    final List<TextSpan> spans = [];

    text.splitMapJoin(
      urlRegex,
      onMatch: (match) {
        final url = match.group(0)!;
        spans.add(
          TextSpan(
            text: url,
            style: const TextStyle(
              color: Colors.blue,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => launchUrlString(url),
          ),
        );
        return '';
      },
      onNonMatch: (nonMatch) {
        spans.add(TextSpan(text: nonMatch));
        return '';
      },
    );

    return spans;
  }
}
