import 'package:flutter/material.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';

/// Dialog for viewing and editing a name with an optional description.
///
/// Used by the skill rubric to edit [SkillDimension]s and [SkillDegree]s.
class SkillDescriptionDialog extends StatefulWidget {
  final String itemType;
  final String initialName;
  final String? initialDescription;
  final bool startInEditMode;
  final Future<void> Function(String name, String? description) onSave;

  const SkillDescriptionDialog({
    super.key,
    required this.itemType,
    required this.initialName,
    this.initialDescription,
    required this.onSave,
    this.startInEditMode = false,
  });

  @override
  State<SkillDescriptionDialog> createState() => _SkillDescriptionDialogState();
}

class _SkillDescriptionDialogState extends State<SkillDescriptionDialog> {
  late bool isEditing;
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  String? nameError;

  @override
  void initState() {
    super.initState();
    isEditing = widget.startInEditMode;
    nameController = TextEditingController(text: widget.initialName);
    descriptionController =
        TextEditingController(text: widget.initialDescription ?? '');
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: isEditing
          ? Text('Edit ${widget.itemType}')
          : Text(widget.initialName),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 400, maxWidth: 500),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children:
                isEditing ? _buildEditContent(context) : _buildPreviewContent(),
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
            onPressed: _save,
            child: const Text('Save'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  List<Widget> _buildEditContent(BuildContext context) {
    return [
      TextFormField(
        controller: nameController,
        decoration: CustomUiConstants.getFilledInputDecoration(
          context,
          labelText: '${widget.itemType} name',
        ).copyWith(errorText: nameError),
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: descriptionController,
        decoration: CustomUiConstants.getFilledInputDecoration(
          context,
          labelText: 'Description',
        ),
        maxLines: null,
        minLines: 5,
        keyboardType: TextInputType.multiline,
      ),
    ];
  }

  List<Widget> _buildPreviewContent() {
    final description = descriptionController.text.trim();
    return [
      Align(
        alignment: Alignment.centerLeft,
        child: description.isEmpty
            ? const Text('No description available.')
            : Text(description),
      ),
    ];
  }

  Future<void> _save() async {
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();

    if (name.isEmpty) {
      setState(() {
        nameError = 'Name cannot be empty';
      });
      return;
    }

    setState(() {
      nameError = null;
    });

    await widget.onSave(name, description.isEmpty ? null : description);
    Navigator.of(context).pop();
  }
}

