import 'package:social_learning/data/data_helpers/teachable_item_category_functions.dart';
import 'package:social_learning/data/data_helpers/teachable_item_functions.dart';
import 'package:social_learning/data/teachable_item.dart';
import 'package:social_learning/data/teachable_item_category.dart';

class PrerequisiteContext {
  final List<TeachableItemCategory> categories;
  final List<TeachableItem> items;
  final void Function() refresh;

  final Map<String, TeachableItem> itemById = {};
  final Map<String, TeachableItemCategory> categoryById = {};
  bool isLoading = true;

  PrerequisiteContext._({
    required this.categories,
    required this.items,
    required this.refresh,
  }) {
    itemById.addEntries(items.map((item) => MapEntry(item.id!, item)));
    categoryById.addEntries(categories.map((cat) => MapEntry(cat.id!, cat)));
    isLoading = false;
  }

  static Future<PrerequisiteContext> create({
    required String courseId,
    required void Function() refresh,
  }) async {
    final categories =
    await TeachableItemCategoryFunctions.getCategoriesForCourse(courseId);
    final items = await TeachableItemFunctions.getItemsForCourse(courseId);
    return PrerequisiteContext._(
      categories: categories,
      items: items,
      refresh: refresh,
    );
  }

  List<TeachableItem> getRequiredPrerequisites(TeachableItem item) {
    return _sortedPrerequisites(item.requiredPrerequisiteIds ?? []);
  }

  List<TeachableItem> getRecommendedPrerequisites(TeachableItem item) {
    return _sortedPrerequisites(item.recommendedPrerequisiteIds ?? []);
  }

  List<TeachableItem> getAllPrerequisites(TeachableItem item) {
    final required = getRequiredPrerequisites(item);
    final recommended = getRecommendedPrerequisites(item);
    return [...required, ...recommended];
  }

  List<TeachableItem> getItemsWithDependencies() {
    final filtered = items.where((item) {
      final hasRequired = item.requiredPrerequisiteIds?.isNotEmpty ?? false;
      final hasRecommended =
          item.recommendedPrerequisiteIds?.isNotEmpty ?? false;
      return hasRequired || hasRecommended;
    }).toList();

    filtered.sort(_itemSortComparator);
    return filtered;
  }

  Future<void> addDependency({
    required TeachableItem target,
    required TeachableItem dependency,
    required bool required,
  }) async {
    final updated = await TeachableItemFunctions.addDependency(
      target: target,
      dependency: dependency,
      required: required,
    );
    _updateItemInContext(updated);
  }

  Future<void> removeDependency({
    required TeachableItem target,
    required TeachableItem dependency,
  }) async {
    final updated = await TeachableItemFunctions.removeDependency(
      target: target,
      dependency: dependency,
    );
    _updateItemInContext(updated);
  }

  Future<void> toggleDependency({
    required TeachableItem target,
    required TeachableItem dependency,
  }) async {
    final updated = await TeachableItemFunctions.toggleDependency(
      target: target,
      dependency: dependency,
    );
    _updateItemInContext(updated);
  }

  List<TeachableItem> _sortedPrerequisites(
      List<dynamic> prereqRefs,
      ) {
    final prereqs = prereqRefs
        .map((ref) => itemById[ref.id])
        .where((item) => item != null)
        .cast<TeachableItem>()
        .toList();

    prereqs.sort(_itemSortComparator);
    return prereqs;
  }

  int _itemSortComparator(TeachableItem a, TeachableItem b) {
    final catA = categoryById[a.categoryId.id];
    final catB = categoryById[b.categoryId.id];

    if (catA == null || catB == null) return 0;

    final catOrder = catA.sortOrder.compareTo(catB.sortOrder);
    if (catOrder != 0) return catOrder;

    return a.sortOrder.compareTo(b.sortOrder);
  }

  void _updateItemInContext(TeachableItem? updated) {
    if (updated == null) return;
    itemById[updated.id!] = updated;
    final index = items.indexWhere((i) => i.id == updated.id);
    if (index != -1) items[index] = updated;
    refresh();
  }

  Map<String, List<TeachableItem>> get itemsGroupedByCategory {
    final Map<String, List<TeachableItem>> map = {};

    for (final item in items) {
      final categoryId = item.categoryId.id;
      map.putIfAbsent(categoryId, () => []);
      map[categoryId]!.add(item);
    }

    // Sort items in each category by sortOrder
    for (final itemList in map.values) {
      itemList.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }

    return map;
  }

}
