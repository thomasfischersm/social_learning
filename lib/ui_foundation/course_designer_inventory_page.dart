import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/teachable_item.dart';
import 'package:social_learning/data/teachable_item_category.dart';
import 'package:social_learning/data/teachable_item_tag.dart';
import 'package:social_learning/state/library_state.dart'; // For selectedCourse
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/edit_teachable_item_dialog.dart';
import 'package:social_learning/ui_foundation/helper_widgets/manage_tags_dialog.dart';
import 'package:social_learning/ui_foundation/helper_widgets/value_input_dialog.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/data/data_helpers/teachable_item_category_functions.dart';
import 'package:social_learning/data/data_helpers/teachable_item_functions.dart';
import 'package:social_learning/data/data_helpers/teachable_item_tag_functions.dart';

class CourseDesignerInventoryPage extends StatefulWidget {
  const CourseDesignerInventoryPage({super.key});

  @override
  State<CourseDesignerInventoryPage> createState() => _CourseDesignerInventoryPageState();
}

class _CourseDesignerInventoryPageState extends State<CourseDesignerInventoryPage> {
  final _newCategoryNameController = TextEditingController();
  final Map<String, TextEditingController> _newItemNameControllers = {};

  List<TeachableItemCategory> _categories = [];
  List<TeachableItem> _items = [];
  List<TeachableItemTag> _tags = [];
  bool _isLoadingCategories = true;
  bool _isLoadingItems = true;
  bool _isLoadingTags = true;

  StreamSubscription? _categoriesSubscription;
  StreamSubscription? _itemsSubscription;
  StreamSubscription? _tagsSubscription;

  String? _courseId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final libraryState = Provider.of<LibraryState>(context, listen: false);
      final course = libraryState.selectedCourse;

      if (course == null || course.id == null) {
        print('Error: No course selected or course ID is missing.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('No course selected. Please select a course first.')));
          setState(() {
            _isLoadingCategories = false;
            _isLoadingItems = false;
            _isLoadingTags = false;
          });
        }
        return;
      }
      _courseId = course.id!;
      final courseRef = FirebaseFirestore.instance.doc('courses/$_courseId');

      _categoriesSubscription = FirebaseFirestore.instance
          .collection('teachableItemCategories')
          .where('courseId', isEqualTo: courseRef)
          .orderBy('sortOrder')
          .snapshots()
          .listen((snapshot) {
        if (mounted) {
          setState(() {
            _categories = snapshot.docs
                .map((doc) => TeachableItemCategory.fromSnapshot(doc))
                .toList();
            _isLoadingCategories = false;
          });
        }
      }, onError: (error) {
        print('Error loading categories: $error');
        if (mounted) {
          setState(() => _isLoadingCategories = false);
          ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Error loading categories: $error')));
        }
      });

      _itemsSubscription = FirebaseFirestore.instance
          .collection('teachableItems')
          .where('courseId', isEqualTo: courseRef)
          .snapshots() // Items are typically ordered within categories or by specific logic
          .listen((snapshot) {
        if (mounted) {
          setState(() {
            _items = snapshot.docs
                .map((doc) => TeachableItem.fromSnapshot(doc))
                .toList();
            _isLoadingItems = false;
          });
        }
      }, onError: (error) {
        print('Error loading items: $error');
        if (mounted) {
          setState(() => _isLoadingItems = false);
          ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Error loading items: $error')));
        }
      });

      _tagsSubscription = FirebaseFirestore.instance
          .collection('teachableItemTags')
          .where('courseId', isEqualTo: courseRef)
          .orderBy('name')
          .snapshots()
          .listen((snapshot) {
        if (mounted) {
          setState(() {
            _tags = snapshot.docs
                .map((doc) => TeachableItemTag.fromSnapshot(doc))
                .toList();
            _isLoadingTags = false;
          });
        }
      }, onError: (error) {
        print('Error loading tags: $error');
        if (mounted) {
          setState(() => _isLoadingTags = false);
          ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Error loading tags: $error')));
        }
      });
    });
  }

  @override
  void dispose() {
    _newCategoryNameController.dispose();
    _newItemNameControllers.forEach((_, controller) => controller.dispose());
    _categoriesSubscription?.cancel();
    _itemsSubscription?.cancel();
    _tagsSubscription?.cancel();
    super.dispose();
  }

  void _showManageTagsDialog(BuildContext context) {
    if (_courseId == null) {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course ID not available to manage tags.')));
      return;
    }
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return ManageTagsDialog(courseId: _courseId!, existingTags: _tags);
      },
    );
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
  Widget build(BuildContext context) {
    if (_courseId == null && !_isLoadingCategories && !_isLoadingItems && !_isLoadingTags) {
       return Scaffold(
        appBar: AppBar(title: const Text('Course Inventory')),
        body: const Center(child: Text('Course not available or error loading data. Please select a course and try again.')),
        bottomNavigationBar: BottomBarV2.build(context),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Inventory'),
      ),
      body: CustomUiConstants.framePage( // framePage provides SingleChildScrollView by default
        enableCreatorGuard: true,
        child: Column( // Removed explicit SingleChildScrollView
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card( // Wrap Tags section in a Card
              margin: const EdgeInsets.all(8.0),
              elevation: 2.0,
              child: Padding(
                padding: const EdgeInsets.all(12.0), // Padding inside the card
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // Card takes minimum vertical space
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0), // Space between title and chips
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('Tags', style: Theme.of(context).textTheme.headlineSmall),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Manage Tags',
                            onPressed: () => _showManageTagsDialog(context),
                          ),
                        ],
                      ),
                    ),
                    _isLoadingTags
                        ? const Center(child: CircularProgressIndicator())
                        : (_tags.isEmpty)
                            ? const Text('No tags yet. Click the pencil to add some!')
                            : Wrap(
                                spacing: 8.0,
                                runSpacing: 8.0,
                                children: _tags.map((tag) {
                                  return Chip(
                                    label: Text(tag.name),
                                    backgroundColor: _parseColor(tag.color, defaultColor: Colors.blueGrey[100]!),
                                    tooltip: 'Tag: ${tag.name}\nColor: ${tag.color}',
                                  );
                                }).toList(),
                              ),
                  ],
                ),
              ),
            ),
            const Divider(height: 32, indent: 16, endIndent: 16),
            Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Categories & Items', style: Theme.of(context).textTheme.headlineSmall),
              ),
              _isLoadingCategories
                  ? const Center(child: CircularProgressIndicator())
                  : _buildCategoriesList(),
              _buildAddCategoryInput(),
              const Divider(height: 32, indent: 16, endIndent: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomBarV2.build(context),
    );
  }

  Widget _buildCategoriesList() {
    if (_isLoadingCategories && _categories.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Center(child: Text('No categories yet. Add one below!')),
      );
    }
    return ListView.builder(
      itemCount: _categories.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final category = _categories[index];
        return ExpansionTile(
          key: PageStorageKey('category_${category.id}'),
          title: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Rename Category',
                  onPressed: () => _editCategoryName(context, category),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  tooltip: 'Delete Category',
                  onPressed: () => _confirmDeleteCategory(context, category),
                ),
              ],
            ),
          ),
          children: [
            _buildItemsList(category.id!),
            _buildAddItemInput(category.id!),
          ],
        );
      },
    );
  }

  Widget _buildAddCategoryInput() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _newCategoryNameController,
              decoration: const InputDecoration(
                hintText: 'Add a new category...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _addNewCategory(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            iconSize: 30,
            tooltip: 'Add Category',
            onPressed: () => _addNewCategory(),
          ),
        ],
      ),
    );
  }

  void _addNewCategory() async {
    if (_courseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Course not selected.')));
      return;
    }
    final name = _newCategoryNameController.text.trim();
    if (name.isNotEmpty) {
      try {
        await TeachableItemCategoryFunctions.addCategory(courseId: _courseId!, name: name);
        _newCategoryNameController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Category "$name" added.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding category: $e')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category name cannot be empty.')),
        );
      }
    }
  }

  void _editCategoryName(BuildContext context, TeachableItemCategory category) async {
    if (category.id == null) return;
    final String? newName = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return ValueInputDialog(
          title: 'Rename Category',
          labelText: 'New Category Name',
          initialValue: category.name,
        );
      },
    );

    if (newName != null && newName.trim().isNotEmpty && newName.trim() != category.name) {
      try {
        await TeachableItemCategoryFunctions.updateCategory(
            categoryId: category.id!, name: newName.trim());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Category renamed to "${newName.trim()}".')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error renaming category: $e')),
          );
        }
      }
    }
  }

  void _confirmDeleteCategory(BuildContext context, TeachableItemCategory category) async {
    if (category.id == null) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Category'),
          content: Text(
              'Are you sure you want to delete the category "${category.name}"? This will also delete all items within this category. This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await TeachableItemCategoryFunctions.deleteCategory(categoryId: category.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Category "${category.name}" deleted.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting category: $e')),
          );
        }
      }
    }
  }

  Widget _buildItemsList(String categoryId) {
    final itemsInCategory = _items
            .where((item) => item.categoryId.id == categoryId)
            .toList();
    
    itemsInCategory.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));


    if (_isLoadingItems && itemsInCategory.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(8.0),
        child: CircularProgressIndicator(key: Key('itemsListLoaderInCategory')),
      ));
    }

    if (itemsInCategory.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Text('No items in this category yet. Add one below!',
            style: TextStyle(fontStyle: FontStyle.italic)),
      );
    }

    return ListView.builder(
      itemCount: itemsInCategory.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final item = itemsInCategory[index];
        final assignedTags = _getTagsFromIds(item.tagIds, _tags);
        final availableTags = _getAvailableTagsForItem(item, _tags);

        return ListTile(
          // leading: (item.notes != null && item.notes!.isNotEmpty) // Removed leading icon
          //     ? const Icon(Icons.notes_outlined, color: Colors.grey)
          //     : const SizedBox(width: 24),
          title: Row( // Option A for notes indicator
            // mainAxisSize: MainAxisSize.min, // Not needed if title takes full width
            children: [
              Expanded( // Use Expanded instead of Flexible for title text
                child: Column( // Keep Column for name and tags
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row( // Row for item name and notes icon
                      children: [
                        Flexible(child: Text(item.name)), // Item name
                        if (item.notes != null && item.notes!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Icon(Icons.subject, size: 16, color: Colors.grey[600]),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4), // Space between name and tags
                    Wrap( // Existing tags Wrap
                      spacing: 6.0,
                      runSpacing: 4.0,
                      children: [
                        ...assignedTags.map((tag) {
                          return Chip(
                            label: Text(tag.name, style: const TextStyle(fontSize: 10)),
                            backgroundColor: _parseColor(tag.color, defaultColor: Colors.blueGrey[100]!),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: const EdgeInsets.all(2),
                            deleteIcon: const Icon(Icons.close_small_outlined, size: 14),
                            onDeleted: () async {
                              if (item.id == null || tag.id == null) return;
                              try {
                                await TeachableItemFunctions.removeItemTagFromItem(
                                    itemId: item.id!, tagRef: FirebaseFirestore.instance.doc('teachableItemTags/${tag.id}'));
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Tag "${tag.name}" removed from "${item.name}".')),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error removing tag: $e')),
                                  );
                                }
                              }
                            },
                          );
                        }).toList(),
                        if (availableTags.isNotEmpty)
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.add_circle_outline, size: 20, color: Colors.blue),
                            tooltip: 'Add Tag',
                            onSelected: (String selectedTagId) async {
                              if (item.id == null) return;
                              try {
                                await TeachableItemFunctions.assignTagToItem(
                                    itemId: item.id!, tagRef: FirebaseFirestore.instance.doc('teachableItemTags/$selectedTagId'));
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Tag added to "${item.name}".')),
                                  );
                                }
                              } catch (e) {
                                 if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error adding tag: $e')),
                                  );
                                }
                              }
                            },
                            itemBuilder: (BuildContext context) {
                              return availableTags.map((tag) {
                                return PopupMenuItem<String>(
                                  value: tag.id!,
                                  child: Row(
                                    children: [
                                      Icon(Icons.circle, color: _parseColor(tag.color), size: 12),
                                      const SizedBox(width: 8),
                                      Text(tag.name),
                                    ],
                                  ),
                                );
                              }).toList();
                            },
                          ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_upward),
                tooltip: 'Move Up',
                onPressed: index == 0 
                    ? null 
                    : () => _moveItemUp(item, itemsInCategory),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_downward),
                tooltip: 'Move Down',
                onPressed: index == itemsInCategory.length - 1 
                    ? null 
                    : () => _moveItemDown(item, itemsInCategory),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Item',
                onPressed: () => _editItem(context, item),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                tooltip: 'Delete Item',
                onPressed: () => _confirmDeleteItem(context, item),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddItemInput(String categoryId) {
    _newItemNameControllers.putIfAbsent(categoryId, () => TextEditingController());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _newItemNameControllers[categoryId],
              decoration: const InputDecoration(
                hintText: 'Add a new item...',
                border: UnderlineInputBorder(),
              ),
              onSubmitted: (_) => _addNewItem(categoryId),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add Item',
            onPressed: () => _addNewItem(categoryId),
          ),
        ],
      ),
    );
  }

  Future<void> _moveItemUp(TeachableItem item, List<TeachableItem> categoryItems) async {
    if (item.id == null) return;
    final index = categoryItems.indexWhere((i) => i.id == item.id);
    if (index <= 0) return; // Should be disabled, but good check

    final itemAbove = categoryItems[index - 1];
    if (itemAbove.id == null) return;

    List<Map<String, dynamic>> itemsToUpdate = [
      {'id': item.id!, 'sortOrder': itemAbove.sortOrder},
      {'id': itemAbove.id!, 'sortOrder': item.sortOrder},
    ];

    try {
      await TeachableItemFunctions.batchUpdateItemSortOrder(itemsToUpdate);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item "${item.name}" moved up.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error moving item: $e')),
        );
      }
    }
  }

  Future<void> _moveItemDown(TeachableItem item, List<TeachableItem> categoryItems) async {
    if (item.id == null) return;
    final index = categoryItems.indexWhere((i) => i.id == item.id);
    if (index < 0 || index >= categoryItems.length - 1) return; // Should be disabled

    final itemBelow = categoryItems[index + 1];
    if (itemBelow.id == null) return;
    
    List<Map<String, dynamic>> itemsToUpdate = [
      {'id': item.id!, 'sortOrder': itemBelow.sortOrder},
      {'id': itemBelow.id!, 'sortOrder': item.sortOrder},
    ];

    try {
      await TeachableItemFunctions.batchUpdateItemSortOrder(itemsToUpdate);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item "${item.name}" moved down.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error moving item: $e')),
        );
      }
    }
  }

  void _addNewItem(String categoryId) async {
    if (_courseId == null) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Course not selected.')));
      return;
    }
    final controller = _newItemNameControllers[categoryId];
    if (controller == null) return;

    final name = controller.text.trim();
    if (name.isNotEmpty) {
      try {
        await TeachableItemFunctions.addItem(
            courseId: _courseId!, categoryId: categoryId, name: name, notes: null);
        controller.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Item "$name" added to category.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding item: $e')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item name cannot be empty.')),
        );
      }
    }
  }

  void _editItem(BuildContext context, TeachableItem item) {
     if (_courseId == null || item.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item or Course ID not available.')));
      return;
    }
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return EditTeachableItemDialog(item: item); 
      },
    ).then((success) {
      if (success == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item "${item.name}" updated.')),
        );
      }
    });
  }

  void _confirmDeleteItem(BuildContext context, TeachableItem item) async {
    if (item.id == null) return;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Item'),
          content: Text(
              'Are you sure you want to delete the item "${item.name}"? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await TeachableItemFunctions.deleteItem(itemId: item.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Item "${item.name}" deleted.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting item: $e')),
          );
        }
      }
    }
  }

  List<TeachableItemTag> _getTagsFromIds(
      List<dynamic>? tagIds, List<TeachableItemTag> allTags) {
    if (tagIds == null ) return [];
    return allTags.where((tag) {
      return tagIds.any((tagIdRef) => tagIdRef is DocumentReference && tagIdRef.id == tag.id);
    }).toList();
  }

  List<TeachableItemTag> _getAvailableTagsForItem(
      TeachableItem item, List<TeachableItemTag> allTags) {
    final assignedTagIds =
        item.tagIds?.map((ref) => ref.id).toSet() ?? <String>{};
    return allTags.where((tag) => !assignedTagIds.contains(tag.id)).toList();
  }
}
