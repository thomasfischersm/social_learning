import 'package:social_learning/data/course_profile.dart';
import 'package:social_learning/data/data_helpers/course_profile_functions.dart';
import 'package:social_learning/data/data_helpers/learning_objective_functions.dart';
import 'package:social_learning/data/data_helpers/teachable_item_category_functions.dart';
import 'package:social_learning/data/data_helpers/teachable_item_functions.dart';
import 'package:social_learning/data/data_helpers/teachable_item_tag_functions.dart';
import 'package:social_learning/data/learning_objective.dart';
import 'package:social_learning/data/teachable_item.dart';
import 'package:social_learning/data/teachable_item_category.dart';
import 'package:social_learning/data/teachable_item_tag.dart';

import '../../../data/lesson.dart';

class LearningObjectivesContext {
  final String courseId;
  final List<LearningObjective> learningObjectives;
  final List<TeachableItem> items;
  final List<TeachableItemCategory> categories;
  final List<TeachableItemTag> tags;
  final CourseProfile? courseProfile;
  final void Function() refresh;

  final Map<String, TeachableItem> itemById = {};
  final Map<String, TeachableItemCategory> categoryById = {};
  final Map<String, TeachableItemTag> tagById = {};

  bool isLoading = true;

  LearningObjectivesContext._({
    required this.courseId,
    required this.learningObjectives,
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

  static Future<LearningObjectivesContext> create({
    required String courseId,
    required void Function() refresh,
  }) async {
    final learningObjectivesFuture =
        LearningObjectiveFunctions.getObjectivesForCourse(courseId);
    final courseProfileFuture =
        CourseProfileFunctions.getCourseProfile(courseId);
    final categoriesFuture =
        TeachableItemCategoryFunctions.getCategoriesForCourse(courseId);
    final itemsFuture = TeachableItemFunctions.getItemsForCourse(courseId);
    final tagsFuture = TeachableItemTagFunctions.getTagsForCourse(courseId);

    final results = await Future.wait([
      learningObjectivesFuture,
      courseProfileFuture,
      categoriesFuture,
      itemsFuture,
      tagsFuture,
    ]);

    final learningObjectives = results[0] as List<LearningObjective>;
    final courseProfile = results[1] as CourseProfile?;
    final categories = results[2] as List<TeachableItemCategory>;
    final items = results[3] as List<TeachableItem>;
    final tags = results[4] as List<TeachableItemTag>;

    return LearningObjectivesContext._(
      courseId: courseId,
      learningObjectives: learningObjectives,
      courseProfile: courseProfile,
      categories: categories,
      items: items,
      tags: tags,
      refresh: refresh,
    );
  }

  List<TeachableItem> getTeachableItemsForCategory(String categoryId) {
    return items.where((item) => item.categoryId.id == categoryId).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  deleteObjective(LearningObjective objective) {
    LearningObjectiveFunctions.deleteObjective(objective);

    // Remove local copy. (It doesn't matter if the sortOrder has a gap.)
    learningObjectives.removeWhere((o) => o.id == objective.id);

    refresh();
  }

  addObjective(String name) async {
    print('(In context) Adding objective: $name');
    // Determine the next sort order.
    int sortOrder = learningObjectives.isEmpty
        ? 0
        : (learningObjectives
                .map((o) => o.sortOrder)
                .reduce((a, b) => a > b ? a : b) +
            1);
    LearningObjective objective = await LearningObjectiveFunctions.addObjective(
        courseId: courseId, name: name, sortOrder: sortOrder);

    learningObjectives.add(objective);

    refresh();
  }

  updateObjective(
      {required String id, required String name, String? description}) async {
    LearningObjective objective =
        await LearningObjectiveFunctions.updateObjective(
      id: id,
      name: name,
      description: description,
    );

    // Replace local copy.
    int index = learningObjectives.indexWhere((o) => o.id == id);
    if (index != -1) {
      learningObjectives[index] = objective;
    }
    refresh();
  }

  /// Attach [lesson] to [item], update local cache, and refresh UI.
  Future<void> addLessonToTeachableItem({
    required TeachableItem item,
    required Lesson lesson,
  }) async {
    final updated = await TeachableItemFunctions.addLessonToTeachableItem(
      itemId: item.id!,
      lessonId: lesson.id!,
    );
    if (updated != null) {
      itemById[item.id!] = updated;
      refresh();
    }
  }

  /// Replace [oldLesson] with [newLesson] on [item], update cache, and refresh.
  Future<void> replaceLessonForTeachableItem({
    required TeachableItem item,
    required Lesson oldLesson,
    required Lesson newLesson,
  }) async {
    // Single function-class call to do remove + add + fetch
    final updated = await TeachableItemFunctions.replaceLessonOnItem(
      itemId: item.id!,
      oldLessonId: oldLesson.id!,
      newLessonId: newLesson.id!,
    );
    if (updated != null) {
      itemById[item.id!] = updated;
      refresh();
    }
  }
  /// Add [item] to the given [objective], update cache, and refresh UI.
  Future<void> addTeachableItemToObjective({
    required LearningObjective objective,
    required TeachableItem item,
  }) async {
    // Delegate to the functions class, which returns the updated objective
    final updated = await LearningObjectiveFunctions.addItemToObjective(
      objectiveId: objective.id!,
      teachableItemId: item.id!,
    );
    if (updated != null) {
      // Replace the old objective in our local list
      final idx = learningObjectives.indexWhere((o) => o.id == objective.id);
      if (idx != -1) {
        learningObjectives[idx] = updated;
      }
    }

    // If the teachable item isn't already included, explicitly select it.
    if (item.inclusionStatus !=
            TeachableItemInclusionStatus.explicitlyIncluded &&
        item.inclusionStatus !=
            TeachableItemInclusionStatus.includedAsPrerequisite) {
      item.inclusionStatus =
          TeachableItemInclusionStatus.explicitlyIncluded;
      await TeachableItemFunctions.updateInclusionStatus(item);

      // Update local caches so UI reflects the change.
      itemById[item.id!] = item;
      final itemIdx = items.indexWhere((i) => i.id == item.id);
      if (itemIdx != -1) items[itemIdx] = item;
    }

    refresh();
  }

  /// Replace [oldItem] with [newItem] on [objective], update cache, refresh UI.
  Future<void> replaceTeachableItemInObjective({
    required LearningObjective objective,
    required TeachableItem oldItem,
    required TeachableItem newItem,
  }) async {
    // Single functions‐class call to remove+add+fetch
    final updated = await LearningObjectiveFunctions.replaceItemInObjective(
      objectiveId: objective.id!,
      oldTeachableItemId: oldItem.id!,
      newTeachableItemId: newItem.id!,
    );
    if (updated != null) {
      final idx = learningObjectives.indexWhere((o) => o.id == objective.id);
      if (idx != -1) {
        learningObjectives[idx] = updated;
      }
      refresh();
    }
  }

  /// Unlinks [item] from [objective], updates local cache and refreshes UI.
  Future<void> removeTeachableItemFromObjective({
    required LearningObjective objective,
    required TeachableItem item,
  }) async {
    // 1) Delegate Firebase work to your functions class
    final updated = await LearningObjectiveFunctions.removeItemFromObjective(
      objectiveId: objective.id!,
      teachableItemId: item.id!,
    );

    // 2) Update in-memory list if we got a fresh model back
    if (updated != null) {
      final idx = learningObjectives.indexWhere((o) => o.id == objective.id);
      if (idx != -1) {
        learningObjectives[idx] = updated;
      }
      // 3) Trigger UI rebuild
      refresh();
    }
  }

  /// Unlink [lesson] from [item], update both caches, then refresh UI.
  Future<void> removeLessonFromTeachableItem({
    required TeachableItem item,
    required Lesson lesson,
  }) async {
    final updated = await TeachableItemFunctions.removeLessonFromTeachableItem(
      itemId: item.id!,
      lessonId: lesson.id!,
    );
    if (updated != null) {
      // 1) Update the map
      itemById[item.id!] = updated;

      // 2) Update the list
      final listIndex = items.indexWhere((i) => i.id == item.id);
      if (listIndex != -1) {
        items[listIndex] = updated;
      }

      // 3) Rebuild the UI
      refresh();
    }
  }
}
