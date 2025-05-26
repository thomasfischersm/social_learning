import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/data_helpers/teachable_item_category_functions.dart';
import 'package:social_learning/data/data_helpers/teachable_item_functions.dart';
import 'package:social_learning/data/teachable_item.dart';
import 'package:social_learning/data/teachable_item_category.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/course_designer_inventory_page.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/add_new_category_entry.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/add_new_item_entry.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/inventory_category_entry.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/inventory_context.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/inventory_entry.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_inventory/inventory_item_entry.dart';
import 'package:social_learning/ui_foundation/ui_constants//custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

class CourseDesignerInventoryPage extends StatefulWidget {
  const CourseDesignerInventoryPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return CourseDesignerInventoryState();
  }
}

class CourseDesignerInventoryState extends State<CourseDesignerInventoryPage>
    implements InventoryContext {
  List<InventoryEntry> inventoryEntries = [];
  bool isLoading = true;

  List<TeachableItemCategory> _categories = [];
  List<TeachableItem> _items = [];

  @override
  List<TeachableItemCategory> getCategories() => _categories;

  @override
  List<TeachableItem> getItems() => _items;

  @override
  List<TeachableItem> getItemsForCategory(String categoryId) =>
      _items.where((item) => item.categoryId.id == categoryId).toList();

  @override
  void initState() {
    super.initState();

    // Delay listener setup to after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final libraryState = Provider.of<LibraryState>(context, listen: false);

      // If the course is already available, load immediately
      if (libraryState.selectedCourse?.id != null) {
        loadInventoryData(libraryState.selectedCourse!.id!);
      } else {
        // Otherwise, watch for changes and react once
        libraryState.addListener(_libraryStateListener);
      }
    });
  }

  @override
  void dispose() {
    final libraryState = Provider.of<LibraryState>(context, listen: false);
    libraryState.removeListener(_libraryStateListener);
    super.dispose();
  }

  void _libraryStateListener() {
    final libraryState = Provider.of<LibraryState>(context, listen: false);
    final selectedCourse = libraryState.selectedCourse;

    if (selectedCourse?.id != null) {
      libraryState.removeListener(_libraryStateListener);
      loadInventoryData(selectedCourse!.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Lab'),
      ),
      bottomNavigationBar: BottomBarV2.build(context),
      body: Align(
        alignment: Alignment.topCenter,
        child: CustomUiConstants.framePage(
          enableScrolling: false,
          enableCreatorGuard: true,
          isLoading
              ? const Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                )
              : ListView.builder(
                  itemCount: inventoryEntries.length,
                  itemBuilder: (context, index) {
                    return inventoryEntries[index].buildWidget(context, () {
                      setState(
                          () {}); // used by entries to trigger local refresh
                    }, this);
                  },
                ),
        ),
      ),
    );
  }

  Future<void> loadInventoryData(String courseId) async {
    setState(() {
      isLoading = true;
    });

    _categories =
        await TeachableItemCategoryFunctions.getCategoriesForCourse(courseId);
    _items = await TeachableItemFunctions.getItemsForCourse(courseId);

    final itemsByCategory = <String, List<TeachableItem>>{};
    for (final item in _items) {
      final categoryId = item.categoryId.id!;
      itemsByCategory.putIfAbsent(categoryId, () => []).add(item);
    }

    inventoryEntries.clear();

    for (final category in _categories
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder))) {
      final categoryEntry = InventoryCategoryEntry(
        category,
        isExpanded: true,
        onDelete: (cat) => _onDeleteCategory(cat),
        contextData: this
      );
      inventoryEntries.add(categoryEntry);

      if (categoryEntry.isExpanded) {
        final itemList = itemsByCategory[category.id] ?? [];
        itemList.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        for (final item in itemList) {
          inventoryEntries.add(InventoryItemEntry(
            item,
            onDelete: (item) => _onDeleteItem(item),
          ));
        }

        inventoryEntries.add(AddNewItemEntry(
          category: category,
          onAdd: (cat, name) => _onAddNewItem(courseId, cat, name),
          contextData: this, // passes InventoryContext
        ));
      }
    }

    inventoryEntries.add(AddNewCategoryEntry(
      onAdd: (name) => _onAddNewCategory(courseId, name),
      contextData: this,
    ));

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _onAddNewItem(
    String courseId,
    TeachableItemCategory category,
    String name,
  ) async {
    final newItem = await TeachableItemFunctions.addItem(
      courseId: courseId,
      categoryId: category.id!,
      name: name,
    );

    if (newItem == null) return;

    // Find the "AddNewItemEntry" after this category
    final insertIndex = inventoryEntries.indexWhere(
      (entry) => entry is AddNewItemEntry && entry.category.id == category.id,
    );

    if (insertIndex == -1) {
      print(
          'Could not find insertion point for new item in category ${category.name}');
      return;
    }

    // Insert new item just before the AddNewItemEntry
    inventoryEntries.insert(insertIndex, InventoryItemEntry(newItem, onDelete: (item) => _onDeleteItem(item),), );
    setState(() {});
  }

  Future<void> _onAddNewCategory(String courseId, String name) async {
    print('_onAddNewCategory: $name');
    TeachableItemCategory? newCategory;

    try {
      newCategory = await TeachableItemCategoryFunctions.addCategory(
        courseId: courseId,
        name: name,
      );
    } catch (e, stack) {
      print('Failed to add category "$name" for course $courseId: $e');
      print('Stack trace:\n$stack');
      return;
    }

    if (newCategory == null) return;

    // Find the position of the AddNewCategoryEntry (which is always last)
    final insertIndex = inventoryEntries.length - 1;

    // Insert the new category and its add-item field just before the final entry
    inventoryEntries.insert(
      insertIndex,
      InventoryCategoryEntry(newCategory, isExpanded: true, onDelete: (cat) => _onDeleteCategory(cat),contextData: this),
    );

    inventoryEntries.insert(
      insertIndex + 1,
      AddNewItemEntry(
        category: newCategory,
        onAdd: (cat, itemName) => _onAddNewItem(courseId, cat, itemName),
        contextData: this,
      ),
    );

    setState(() {});
  }

  Future<void> _onDeleteItem(TeachableItem item) async {
    await TeachableItemFunctions.deleteItem(itemId: item.id!);

    inventoryEntries.removeWhere(
      (entry) => entry is InventoryItemEntry && entry.item.id == item.id,
    );

    setState(() {});
  }

  Future<void> _onDeleteCategory(TeachableItemCategory category) async {
    await TeachableItemCategoryFunctions.deleteCategory(
        categoryId: category.id!);

    inventoryEntries.removeWhere((entry) {
      if (entry is InventoryCategoryEntry && entry.category.id == category.id)
        return true;
      if (entry is InventoryItemEntry &&
          entry.item.categoryId.id == category.id) return true;
      if (entry is AddNewItemEntry && entry.category.id == category.id)
        return true;
      return false;
    });

    setState(() {});
  }
}
