import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/data_helpers/reference_helper.dart';
import 'package:social_learning/cloud_functions/cloud_functions.dart';
import 'package:social_learning/cloud_functions/inventory_generation_response.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/course_profile.dart';
import 'package:social_learning/data/data_helpers/course_profile_functions.dart';
import 'package:social_learning/data/data_helpers/teachable_item_category_functions.dart';
import 'package:social_learning/data/data_helpers/teachable_item_functions.dart';
import 'package:social_learning/data/data_helpers/teachable_item_tag_functions.dart';
import 'package:social_learning/data/teachable_item.dart';
import 'package:social_learning/data/teachable_item_category.dart';
import 'package:social_learning/data/teachable_item_tag.dart';
import 'inventory_category_entry.dart';
import 'inventory_context.dart';
import 'inventory_entry.dart';
import 'inventory_item_entry.dart';
import 'add_new_category_entry.dart';
import 'add_new_item_entry.dart';

class InventoryDataContext implements InventoryContext {
  final String courseId;
  final Course? course;
  final void Function() refresh;

  InventoryDataContext._({
    required this.courseId,
    required this.course,
    required this.refresh,
  });

  bool isLoading = true;
  bool _processingQueue = false;
  bool _loadQueued = false;

  List<TeachableItemCategory> _categories = [];
  List<TeachableItem> _items = [];
  List<TeachableItemTag> _tags = [];
  CourseProfile? _courseProfile;

  List<InventoryEntry> inventoryEntries = [];

  static InventoryDataContext create({
    required String courseId,
    required Course? course,
    required void Function() refresh,
  }) {
    final ctx = InventoryDataContext._(
      courseId: courseId,
      course: course,
      refresh: refresh,
    );
    ctx.loadInventoryData();
    return ctx;
  }

  @override
  List<TeachableItemCategory> getCategories() => _categories;

  @override
  List<TeachableItem> getItems() => _items;

  @override
  List<TeachableItemTag> getTags() => _tags;

  @override
  List<TeachableItem> getItemsForCategory(String categoryId) =>
      _items.where((item) => item.categoryId.id == categoryId).toList();

  @override
  List<InventoryEntry> getInventoryEntries() => inventoryEntries;

  @override
  Course? getCourse() => course;

  @override
  CourseProfile? getCourseProfile() => _courseProfile;

  @override
  Future<void> saveGeneratedInventory(List<GeneratedCategory> generated) async {
    final categoryNames = generated.map((e) => e.category).toList();
    final newCategories = await TeachableItemCategoryFunctions.bulkCreateCategories(
      courseId: courseId,
      names: categoryNames,
    );

    final courseRef = docRef('courses', courseId);
    final items = <TeachableItem>[];
    for (int i = 0; i < newCategories.length; i++) {
      final cat = newCategories[i];
      final catRef = docRef('teachableItemCategories', cat.id!);
      final names = generated[i].items;
      for (int j = 0; j < names.length; j++) {
        items.add(
          TeachableItem(
            courseId: courseRef,
            categoryId: catRef,
            name: names[j],
            sortOrder: j,
            createdAt: Timestamp.now(),
            modifiedAt: Timestamp.now(),
            notes: null,
          ),
        );
      }
    }

    await TeachableItemFunctions.bulkCreateItems(items);
  }

  void loadInventoryData() {
    _loadQueued = true;
    if (_processingQueue) return;
    _processingQueue = true;
    _processQueue();
  }

  Future<void> _processQueue() async {
    while (_loadQueued) {
      _loadQueued = false;
      await _loadInventoryDataInternal();
    }
    _processingQueue = false;
    if (_loadQueued) {
      loadInventoryData();
    }
  }

  Future<void> _loadInventoryDataInternal() async {
    isLoading = true;
    refresh();

    final results = await Future.wait([
      CourseProfileFunctions.getCourseProfile(courseId),
      TeachableItemCategoryFunctions.getCategoriesForCourse(courseId),
      TeachableItemFunctions.getItemsForCourse(courseId),
      TeachableItemTagFunctions.getTagsForCourse(courseId),
    ]);

    _courseProfile = results[0] as CourseProfile?;
    _categories = results[1] as List<TeachableItemCategory>;
    _items = results[2] as List<TeachableItem>;
    _tags = results[3] as List<TeachableItemTag>;

    final itemsByCategory = <String, List<TeachableItem>>{};
    for (final item in _items) {
      final categoryId = item.categoryId.id!;
      itemsByCategory.putIfAbsent(categoryId, () => []).add(item);
    }

    inventoryEntries.clear();

    for (final category in _categories..sort((a, b) => a.sortOrder.compareTo(b.sortOrder))) {
      final categoryEntry = InventoryCategoryEntry(
        category,
        isExpanded: true,
        onDelete: (cat) => deleteCategory(cat),
        contextData: this,
      );
      inventoryEntries.add(categoryEntry);

      if (categoryEntry.isExpanded) {
        final itemList = itemsByCategory[category.id] ?? [];
        itemList.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        for (final item in itemList) {
          inventoryEntries.add(
            InventoryItemEntry(
              item,
              onDelete: (itm) => deleteItem(itm),
            ),
          );
        }

        inventoryEntries.add(
          AddNewItemEntry(
            category: category,
            onAdd: (cat, name) => addNewItem(cat, name),
            contextData: this,
          ),
        );
      }
    }

    inventoryEntries.add(
      AddNewCategoryEntry(
        onAdd: (name) => addNewCategory(name),
        onGenerate: generateInventory,
        contextData: this,
      ),
    );

    isLoading = false;
    refresh();
  }

  Future<void> addNewItem(TeachableItemCategory category, String name) async {
    final newItem = await TeachableItemFunctions.addItem(
      courseId: courseId,
      categoryId: category.id!,
      name: name,
    );

    if (newItem == null) return;

    _items.add(newItem);

    final insertIndex = inventoryEntries.indexWhere(
        (entry) => entry is AddNewItemEntry && entry.category.id == category.id);

    if (insertIndex == -1) return;

    inventoryEntries.insert(
      insertIndex,
      InventoryItemEntry(newItem, onDelete: (itm) => deleteItem(itm)),
    );

    refresh();
  }

  Future<void> addNewCategory(String name) async {
    TeachableItemCategory? newCategory;
    try {
      newCategory = await TeachableItemCategoryFunctions.addCategory(
        courseId: courseId,
        name: name,
      );
    } catch (e, stack) {
      print('Failed to add category "$name": $e\n$stack');
      return;
    }

    if (newCategory == null) return;

    _categories.add(newCategory);

    final insertIndex = inventoryEntries.length - 1;

    inventoryEntries.insert(
      insertIndex,
      InventoryCategoryEntry(
        newCategory,
        isExpanded: true,
        onDelete: (cat) => deleteCategory(cat),
        contextData: this,
      ),
    );

    inventoryEntries.insert(
      insertIndex + 1,
      AddNewItemEntry(
        category: newCategory,
        onAdd: (cat, itemName) => addNewItem(cat, itemName),
        contextData: this,
      ),
    );

    refresh();
  }

  Future<void> deleteItem(TeachableItem item) async {
    await TeachableItemFunctions.deleteItem(itemId: item.id!);

    _items.removeWhere((i) => i.id == item.id);
    inventoryEntries.removeWhere(
      (entry) => entry is InventoryItemEntry && entry.item.id == item.id,
    );

    refresh();
  }

  Future<void> deleteCategory(TeachableItemCategory category) async {
    await TeachableItemCategoryFunctions.deleteCategory(
        categoryId: category.id!);

    _categories.removeWhere((c) => c.id == category.id);
    _items.removeWhere((item) => item.categoryId.id == category.id);

    inventoryEntries.removeWhere((entry) {
      if (entry is InventoryCategoryEntry && entry.category.id == category.id) return true;
      if (entry is InventoryItemEntry && entry.item.categoryId.id == category.id) return true;
      if (entry is AddNewItemEntry && entry.category.id == category.id) return true;
      return false;
    });

    refresh();
  }

  Future<void> generateInventory() async {
    if (course == null) return;

    isLoading = true;
    refresh();
    try {
      final response = await CloudFunctions.generateCourseInventory(
        course!,
        _courseProfile,
      );
      await saveGeneratedInventory(response.categories);
    } catch (e, stack) {
      print('Failed to generate inventory: $e\n$stack');
    }

    loadInventoryData();
  }
}
