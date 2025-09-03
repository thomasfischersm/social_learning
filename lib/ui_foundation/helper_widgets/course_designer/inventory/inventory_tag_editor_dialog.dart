import 'package:flutter/material.dart';
import 'package:social_learning/data/teachable_item_tag.dart';
import 'package:social_learning/data/data_helpers/teachable_item_tag_functions.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/inventory/color_picker_dialog.dart';
import 'package:social_learning/ui_foundation/helper_widgets/dialog_utils.dart';
import 'package:social_learning/ui_foundation/helper_widgets/value_input_dialog.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';

class InventoryTagEditorDialog extends StatefulWidget {
  final List<TeachableItemTag> initialTags;
  final String courseId;

  const InventoryTagEditorDialog({
    super.key,
    required this.initialTags,
    required this.courseId,
  });

  @override
  State<InventoryTagEditorDialog> createState() =>
      _InventoryTagEditorDialogState();
}

class _InventoryTagEditorDialogState extends State<InventoryTagEditorDialog> {
  late List<_EditableTag> tags;
  final TextEditingController _newTagController = TextEditingController();
  Color? _newTagColor;

  static const List<Color> _preferredColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.amber,
    Colors.indigo,
    Colors.cyan,
    Colors.lime,
    Colors.brown,
    Colors.deepOrange,
    Colors.deepPurple,
    Colors.lightGreen,
    Colors.lightBlue,
    Colors.blueGrey,
  ];

  @override
  void initState() {
    super.initState();
    tags = widget.initialTags.map((t) => _EditableTag(tag: t)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Tags'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...tags.map(_buildTagRow),
          const Divider(height: 24),
          _buildNewTagRow(),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            if (_newTagController.text.trim().isNotEmpty) {
              DialogUtils.showConfirmationDialog(
                context,
                'Are you done?',
                'You\'ve started creating a new tag. However, you haven\'t hit the + button to create it.\n\nAre you sure you want to leave?',
                () => Navigator.of(context).pop(),
              );
            } else {
              Navigator.of(context).pop();
            }
          },
          child: const Text('Done'),
        ),
      ],
    );
  }

  Widget _buildTagRow(_EditableTag tag) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          // Color circle
          InkWell(
            onTap: () => _showColorPicker(tag),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _tryParseColor(tag.tag.color),
                border: Border.all(color: Colors.black26),
              ),
            ),
          ),

          // Tag name
          Expanded(
            child: Text(tag.tag.name, style: const TextStyle(fontSize: 14)),
          ),

          // Edit icon
          IconButton(
            icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
            tooltip: 'Edit name',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => ValueInputDialog(
                  'Edit Tag Name',
                  tag.tag.name,
                  'Enter new name',
                  'Save',
                      (val) {
                    final trimmed = val?.trim() ?? '';
                    if (trimmed.isEmpty) return 'Name cannot be empty';
                    final isDuplicate = tags.any((t) =>
                    t.tag.id != tag.tag.id &&
                        t.tag.name.toLowerCase().trim() ==
                            trimmed.toLowerCase());
                    if (isDuplicate) {
                      return 'Another tag with this name already exists.';
                    }
                    return null;
                  },
                      (newName) async {
                    await TeachableItemTagFunctions.updateTag(
                      tagId: tag.tag.id!,
                      name: newName,
                      color: tag.tag.color,
                    );
                    setState(() {
                      tag.tag = tag.tag.copyWith(name: newName);
                    });
                  },
                ),
              );
            },
          ),

          // Delete icon
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            tooltip: 'Delete tag',
            onPressed: () => DialogUtils.showConfirmationDialog(
              context,
              'Delete Tag',
              'Are you sure you want to delete the tag "${tag.tag.name}"?',
                  () async {
                await TeachableItemTagFunctions.deleteTag(tagId: tag.tag.id!);
                setState(() => tags.remove(tag));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewTagRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _newTagController,
            decoration: CustomUiConstants.getFilledInputDecoration(
              context,
              labelText: 'New tag',
              enabledColor: Colors.grey.shade300,
            ).copyWith(isDense: true),
            onSubmitted: (_) => _addNewTag(),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: _showNewColorPicker,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _newTagColor ?? _getSuggestedColor(),
              border: Border.all(color: Colors.black26),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: 'Add tag',
          onPressed: _addNewTag,
        ),
      ],
    );
  }

  void _showColorPicker(_EditableTag tag) {
    showDialog(
      context: context,
      builder: (context) => ColorPickerDialog(
        onColorSelected: (color) async {
          final hex = _colorToHex(color);
          await TeachableItemTagFunctions.updateTag(
            tagId: tag.tag.id!,
            name: tag.tag.name,
            color: hex,
          );
          setState(() {
            tag.tag = tag.tag.copyWith(color: hex);
          });
        },
      ),
    );
  }

  void _showNewColorPicker() {
    showDialog(
      context: context,
      builder: (context) => ColorPickerDialog(
        onColorSelected: (color) {
          setState(() => _newTagColor = color);
        },
      ),
    );
  }

  Future<void> _addNewTag() async {
    final name = _newTagController.text.trim();
    if (name.isEmpty) return;

    final color = _newTagColor ?? _getSuggestedColor();
    final newTag = await TeachableItemTagFunctions.addTag(
      courseId: widget.courseId,
      name: name,
      color: _colorToHex(color),
    );

    if (newTag != null) {
      setState(() {
        tags.add(_EditableTag(tag: newTag));
        _newTagController.clear();
        _newTagColor = null;
      });
    } else {
      DialogUtils.showInfoDialog(
        context,
        "Tag Creation Failed",
        "An error occurred while adding the tag.",
            () {},
      );
    }
  }

  Color _getSuggestedColor() {
    final usedHexes =
    tags.map((t) => t.tag.color.toLowerCase().replaceAll('#', '')).toSet();

    for (final color in _preferredColors) {
      final hex = _colorToHex(color).replaceAll('#', '').toLowerCase();
      if (!usedHexes.contains(hex)) {
        return color;
      }
    }

    return Colors.grey;
  }

  Color _tryParseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xff')));
    } catch (_) {
      return Colors.grey;
    }
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }
}

class _EditableTag {
  TeachableItemTag tag;
  bool isEditing = false;
  final TextEditingController controller;

  _EditableTag({required this.tag})
      : controller = TextEditingController(text: tag.name);
}

extension on TeachableItemTag {
  TeachableItemTag copyWith({String? name, String? color}) {
    return TeachableItemTag(
      id: id,
      courseId: courseId,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt,
      modifiedAt: modifiedAt,
    );
  }
}
