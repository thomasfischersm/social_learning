import 'package:social_learning/data/teachable_item.dart';
import 'package:social_learning/data/teachable_item_category.dart';
import 'package:social_learning/data/teachable_item_inclusion_status.dart';
import 'package:social_learning/data/teachable_item_tag.dart';
import 'package:social_learning/data/course_profile.dart';

import 'package:social_learning/data/data_helpers/teachable_item_functions.dart';
import 'package:social_learning/data/data_helpers/teachable_item_category_functions.dart';
import 'package:social_learning/data/data_helpers/teachable_item_tag_functions.dart';
import 'package:social_learning/data/data_helpers/course_profile_functions.dart';

class ScopeContext {
  final List<TeachableItem> items;
  final List<TeachableItemCategory> categories;
  final List<TeachableItemTag> tags;
  final CourseProfile? courseProfile;
  final void Function() refresh;

  final Map<String, TeachableItem> itemById = {};
  final Map<String, TeachableItemCategory> categoryById = {};
  final Map<String, TeachableItemTag> tagById = {};

  final Set<String> requiredItemIds = {};
  final Set<String> recommendedItemIds = {};

  bool isLoading = true;

  ScopeContext._({
    required this.items,
    required this.categories,
    required this.tags,
    required this.courseProfile,
    required this.refresh,
  }) {
    itemById.addEntries(items.map((item) => MapEntry(item.id!, item)));
    categoryById.addEntries(categories.map((cat) => MapEntry(cat.id!, cat)));
    tagById.addEntries(tags.map((tag) => MapEntry(tag.id!, tag)));
    isLoading = false;
  }

  static Future<ScopeContext> create({
    required String courseId,
    required void Function() refresh,
  }) async {
    final courseProfileFuture =
        CourseProfileFunctions.getCourseProfile(courseId);
    final categoriesFuture =
        TeachableItemCategoryFunctions.getCategoriesForCourse(courseId);
    final itemsFuture = TeachableItemFunctions.getItemsForCourse(courseId);
    final tagsFuture = TeachableItemTagFunctions.getTagsForCourse(courseId);

    final results = await Future.wait([
      courseProfileFuture,
      categoriesFuture,
      itemsFuture,
      tagsFuture,
    ]);

    final courseProfile = results[0] as CourseProfile?;
    final categories = results[1] as List<TeachableItemCategory>;
    final items = results[2] as List<TeachableItem>;
    final tags = results[3] as List<TeachableItemTag>;

    return ScopeContext._(
      courseProfile: courseProfile,
      categories: categories,
      items: items,
      tags: tags,
      refresh: refresh,
    );
  }

  _initRequireRecommendedItemIds() {
    print('Initializing required and recommended item IDs...');
    requiredItemIds.clear();
    recommendedItemIds.clear();

    Set<TeachableItem> explicitlySelectedItems = items
        .where((item) =>
            item.inclusionStatus ==
            TeachableItemInclusionStatus.explicitlyIncluded)
        .toSet();

    print('Explicitly selected items: ${explicitlySelectedItems.length}');

    Set<TeachableItem> requiredItemsToVisit = {};
    Set<TeachableItem> recommendedItemsToVisit = {};

    // Seed with required/recommended items from explicitly selected items.
    // Be sure to promote recommended to required if there is a required
    // reference.
    for (TeachableItem item in explicitlySelectedItems) {
      if (item.requiredPrerequisiteIds != null) {
        for (var ref in item.requiredPrerequisiteIds!) {
          final requiredItem = itemById[ref.id];
          if (requiredItem != null) {
            requiredItemsToVisit.add(requiredItem);
            recommendedItemsToVisit.remove(requiredItem);
          }
        }
      }
      if (item.recommendedPrerequisiteIds != null) {
        for (var ref in item.recommendedPrerequisiteIds!) {
          final recommendedItem = itemById[ref.id];
          if ((recommendedItem != null) &&
              (!requiredItemsToVisit.contains(recommendedItem))) {
            recommendedItemsToVisit.add(recommendedItem);
          }
        }
      }
    }

    print('Initial required items to visit: ${requiredItemsToVisit.length} and ${recommendedItemsToVisit.length}');
    while (
        requiredItemsToVisit.isNotEmpty || recommendedItemsToVisit.isNotEmpty) {
      // Visit required items.
      if (requiredItemsToVisit.isNotEmpty) {
        final item = requiredItemsToVisit.first;
        requiredItemsToVisit.remove(item);
        print('Visiting required item: ${item.name}');

        // Stop here if the user excluded the item.
        if (item.inclusionStatus == TeachableItemInclusionStatus.explicitlyExcluded) {
          continue;
        }

        requiredItemIds.add(item.id!);
        recommendedItemIds.remove(item.id!);
        recommendedItemsToVisit.remove(item);

        // Add required prerequisites to visit.
        if (item.requiredPrerequisiteIds != null) {
          for (var ref in item.requiredPrerequisiteIds!) {
            final requiredItem = itemById[ref.id];
            if ((requiredItem != null) &&
                (!requiredItemIds.contains(requiredItem.id!))) {
              requiredItemsToVisit.add(requiredItem);
            }
          }
        }

        // Add recommended prerequisites to visit.
        if (item.recommendedPrerequisiteIds != null) {
          for (var ref in item.recommendedPrerequisiteIds!) {
            final recommendedItem = itemById[ref.id];
            if ((recommendedItem != null) &&
                (!requiredItemsToVisit.contains(recommendedItem)) &&
                (!requiredItemIds.contains(recommendedItem.id!)) &&
                (!recommendedItemIds.contains(recommendedItem.id!))) {
              recommendedItemsToVisit.add(recommendedItem);
            }
          }
        }
      } else if (recommendedItemsToVisit.isNotEmpty) {
        // Visit recommended items.
        final item = recommendedItemsToVisit.first;
        recommendedItemsToVisit.remove(item);
        print('Visiting recommended item: ${item.name}');

        // Stop here if the user excluded the item.
        if (item.inclusionStatus == TeachableItemInclusionStatus.explicitlyExcluded) {
          continue;
        }

        // Stop if the item is already required.
        if (requiredItemIds.contains(item.id!)) {
          continue;
        }

        recommendedItemIds.add(item.id!);

        // Add required prerequisites to visit. However, because they
        // come from something recommended, they are only recommended as well.
        if (item.requiredPrerequisiteIds != null) {
          for (var ref in item.requiredPrerequisiteIds!) {
            final requiredItem = itemById[ref.id];
            if ((requiredItem != null) &&
                (!requiredItemIds.contains(requiredItem.id!)) &&
                (!recommendedItemsToVisit.contains(requiredItem)) &&
                (!requiredItemsToVisit.contains(requiredItem))) {
              recommendedItemsToVisit.add(requiredItem);
            }
          }
        }

        // Add recommended prerequisites to visit.
        if (item.recommendedPrerequisiteIds != null) {
          for (var ref in item.recommendedPrerequisiteIds!) {
            final recommendedItem = itemById[ref.id];
            if ((recommendedItem != null) &&
                (!requiredItemsToVisit.contains(recommendedItem)) &&
                (!requiredItemIds.contains(recommendedItem.id!)) &&
                (!recommendedItemIds.contains(recommendedItem.id!))) {
              recommendedItemsToVisit.add(recommendedItem);
            }
          }
        }
      }
    }

    print(
        'Done initializing required and recommended item IDs: Required: ${requiredItemIds.length} Recommended: ${recommendedItemIds.length}');
  }

  _updateInclusionStatuses() {
    Set<TeachableItem> needToSelect = {};
    Set<TeachableItem> needToDeselect = {};

    // Determine if any items need to be selected or deselected.
    for (final item in items) {
      // Skip items that are explicitly included or excluded.
      if (item.inclusionStatus ==
              TeachableItemInclusionStatus.explicitlyIncluded ||
          item.inclusionStatus ==
              TeachableItemInclusionStatus.explicitlyExcluded) {
        continue;
      }

      bool isImplicitlyIncluded = requiredItemIds.contains(item.id!) ||
          recommendedItemIds.contains(item.id!);

      if (isImplicitlyIncluded &&
          item.inclusionStatus == TeachableItemInclusionStatus.excluded) {
        needToSelect.add(item);
      } else if (!isImplicitlyIncluded &&
          item.inclusionStatus ==
              TeachableItemInclusionStatus.includedAsPrerequisite) {
        needToDeselect.add(item);
      }
    }

    // Update in Firebase.
    TeachableItemFunctions.updateInclusionStatuses(
      needToSelect,
      needToDeselect,
    );

    // Update local context.
    for (final item in needToSelect) {
      item.inclusionStatus =
          TeachableItemInclusionStatus.includedAsPrerequisite;
    }
    for (final item in needToDeselect) {
      item.inclusionStatus = TeachableItemInclusionStatus.excluded;
    }
  }

  List<TeachableItem> getItemsForCategory(String categoryId) {
    return items.where((item) => item.categoryId.id == categoryId).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  List<TeachableItemTag> getTagsForItem(TeachableItem item) {
    final refs = item.tagIds ?? [];
    return refs
        .map((ref) => tagById[ref.id])
        .where((tag) => tag != null)
        .cast<TeachableItemTag>()
        .toList();
  }

  Future<void> saveInstructionalPercentage(int instructionalPercent) async {
    if (courseProfile == null) {
      return;
    }
    courseProfile!.instructionalTimePercent = instructionalPercent;
    await CourseProfileFunctions.saveCourseProfile(courseProfile!);
    refresh();
  }

  saveSessionDuration(
      int? sessionCount, int? sessionDuration, int? totalMinutes) {
    if (courseProfile == null) {
      return;
    }
    courseProfile!.sessionCount = sessionCount;
    courseProfile!.sessionDurationInMinutes = sessionDuration;
    courseProfile!.totalCourseDurationInMinutes = totalMinutes;
    CourseProfileFunctions.saveCourseProfile(courseProfile!);
    refresh();
  }

  void saveDefaultTeachableItemDuration(int newDuration) {
    if (courseProfile == null) {
      return;
    }
    courseProfile!.defaultTeachableItemDurationInMinutes = newDuration;
    CourseProfileFunctions.saveCourseProfile(courseProfile!);
    refresh();
  }

  int getSelectedItemsTotalMinutes() {
    if (courseProfile == null) return 0;
    final defaultDuration =
        courseProfile!.defaultTeachableItemDurationInMinutes ?? 15;
    return items
        .where((item) =>
            item.inclusionStatus ==
                TeachableItemInclusionStatus.explicitlyIncluded ||
            item.inclusionStatus ==
                TeachableItemInclusionStatus.includedAsPrerequisite)
        .fold<int>(
          0,
          (sum, item) => sum + (item.durationInMinutes ?? defaultDuration),
        );
  }

  toggleItemInclusionStatus(TeachableItem item) async {
    switch (item.inclusionStatus) {
      case TeachableItemInclusionStatus.excluded:
        // Select the item.
        item.inclusionStatus = TeachableItemInclusionStatus.explicitlyIncluded;
        break;
      case TeachableItemInclusionStatus.includedAsPrerequisite:
        // Already selected, so explicitly exclude it.
        item.inclusionStatus = TeachableItemInclusionStatus.explicitlyExcluded;
        break;
      case TeachableItemInclusionStatus.explicitlyIncluded:
        // Explicitly included, so remove the explicit inclusion and let auto
        // prerequisite fix it later.
        item.inclusionStatus = TeachableItemInclusionStatus.excluded;
        break;
      case TeachableItemInclusionStatus.explicitlyExcluded:
        // Explicitly excluded, so remove the explicit exclusion and let auto
        // prerequisite fix it later.
        item.inclusionStatus = TeachableItemInclusionStatus.excluded;
        break;
      default:
        return; // No change needed
    }

    await TeachableItemFunctions.updateInclusionStatus(item);

    // Do cascading updates.
    _initRequireRecommendedItemIds();
    _updateInclusionStatuses();

    refresh();
  }

  void saveItemDurationOverride(TeachableItem item, int? newDurationOverride) async {
    if (item.durationInMinutes == newDurationOverride) {
      return; // No change needed
    }
    item.durationInMinutes = newDurationOverride;
    await TeachableItemFunctions.updateDurationOverride(item, newDurationOverride);
    refresh();
  }
}
