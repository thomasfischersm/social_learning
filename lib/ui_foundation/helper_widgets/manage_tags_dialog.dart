import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
// Removed Provider import as LibraryState is no longer used directly
import 'package:social_learning/data/teachable_item_tag.dart';
import 'package:social_learning/data/data_helpers/teachable_item_tag_functions.dart'; // Added

class ManageTagsDialog extends StatefulWidget {
  final String courseId; // Added
  final List<TeachableItemTag> existingTags; // Added

  const ManageTagsDialog({
    super.key,
    required this.courseId, // Added
    required this.existingTags, // Added
  });

  @override
  State<ManageTagsDialog> createState() => _ManageTagsDialogState();
}

class _ManageTagsDialogState extends State<ManageTagsDialog> {
  // _courseId is now passed via widget.courseId
  final _tagNameController = TextEditingController();
  final _tagColorController = TextEditingController(text: '#'); // Default to hex prefix

  TeachableItemTag? _editingTag; // To hold the tag being edited

  // Default color for the picker
  Color _currentColor = Colors.blue;

  void _pickColor() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _currentColor,
              onColorChanged: (Color color) {
                setState(() => _currentColor = color);
              },
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Done'),
              onPressed: () {
                setState(() {
                  _tagColorController.text =
                      '#${_currentColor.value.toRadixString(16).substring(2).toUpperCase()}';
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(TeachableItemTag tag) {
    if (tag.id == null) return;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Tag'),
          content: Text('Are you sure you want to delete the tag "${tag.name}"? This cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () {
                // Call static function
                TeachableItemTagFunctions.deleteTag(tagId: tag.id!).then((_) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Tag "${tag.name}" deleted.')),
                    );
                    if (_editingTag?.id == tag.id) {
                      _clearEditingFields();
                    }
                  }
                }).catchError((error) {
                   if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting tag: $error')),
                    );
                  }
                });
                Navigator.of(dialogContext).pop(); 
              },
            ),
          ],
        );
      },
    );
  }

  void _startEditing(TeachableItemTag tag) {
    setState(() {
      _editingTag = tag;
      _tagNameController.text = tag.name;
      _tagColorController.text = tag.color;
      try {
        _currentColor = Color(int.parse(tag.color.substring(1), radix: 16) + 0xFF000000);
      } catch (e) {
        _currentColor = Colors.grey; // Default if parse fails
      }
    });
  }

  void _clearEditingFields() {
    setState(() {
      _editingTag = null;
      _tagNameController.clear();
      _tagColorController.text = '#';
      _currentColor = Colors.blue; // Reset to default
    });
  }

  void _submitTag() {
    final name = _tagNameController.text.trim();
    final color = _tagColorController.text.trim();

    if (name.isEmpty || !RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(color)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid name or color format (e.g., #RRGGBB).')),
      );
      return;
    }

    if (_editingTag != null) {
      // Update existing tag
      // Note: TeachableItemTag no longer has courseId, createdAt, modifiedAt, creatorId in constructor
      // These are handled by Firestore or not directly updatable in this manner by client.
      // The TeachableItemTagFunctions.updateTag only needs tagId, name, and color.
      TeachableItemTagFunctions.updateTag(
        tagId: _editingTag!.id!,
        name: name,
        color: color,
      ).then((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tag "$name" updated.')),
          );
          _clearEditingFields();
        }
      }).catchError((error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating tag: $error')),
          );
        }
      });
    } else {
      // Add new tag
      TeachableItemTagFunctions.addTag(
        courseId: widget.courseId, // Use widget.courseId
        name: name,
        color: color,
      ).then((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tag "$name" added.')),
          );
          _clearEditingFields();
        }
      }).catchError((error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding tag: $error')),
          );
        }
      });
    }
  }
  
  Color _parseColor(String colorString, {Color defaultColor = Colors.grey}) {
    if (colorString.startsWith('#') && colorString.length >= 7) {
      try {
        return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
      } catch (e) {
        print('Error parsing color: $colorString, error: $e');
        return defaultColor;
      }
    }
    return defaultColor;
  }


  @override
  void dispose() {
    _tagNameController.dispose();
    _tagColorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use widget.existingTags instead of LibraryState
    final tags = widget.existingTags;

    return AlertDialog(
      title: Text(_editingTag == null ? 'Manage Tags' : 'Edit Tag "${_editingTag!.name}"'),
      content: SizedBox(
        width: double.maxFinite, // Make dialog wider
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (_editingTag == null) ...[
                 Text('Existing Tags', style: Theme.of(context).textTheme.titleMedium),
                (tags.isEmpty)
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('No tags yet. Add one below!'),
                      )
                    : ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.3, // Limit height
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: tags.length,
                          itemBuilder: (context, index) {
                            final tag = tags[index];
                            return ListTile(
                              leading: Icon(Icons.circle, color: _parseColor(tag.color)),
                              title: Text(tag.name),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_note_outlined),
                                    tooltip: 'Edit Tag',
                                    onPressed: () => _startEditing(tag),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    tooltip: 'Delete Tag',
                                    onPressed: () => _showDeleteConfirmationDialog(tag),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                const Divider(height: 24),
              ],
              Text(_editingTag == null ? 'Add New Tag' : 'Edit Details',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _tagNameController,
                decoration: const InputDecoration(
                  labelText: 'Tag Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _tagColorController,
                decoration: InputDecoration(
                  labelText: 'Tag Color (e.g., #RRGGBB)',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.color_lens_outlined, color: _currentColor),
                    tooltip: 'Pick Color',
                    onPressed: _pickColor,
                  )
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_editingTag != null)
                    TextButton(
                      child: const Text('Cancel Edit'),
                      onPressed: _clearEditingFields,
                    ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _submitTag,
                    child: Text(_editingTag == null ? 'Add Tag' : 'Save Changes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Close'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
