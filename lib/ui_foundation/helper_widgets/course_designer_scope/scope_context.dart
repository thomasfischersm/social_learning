import 'package:social_learning/data/teachable_item.dart';
import 'package:social_learning/data/teachable_item_category.dart';
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

  int getSelectedItemsTotalMinutes() {
    if (courseProfile == null) return 0;
    final defaultDuration =
        courseProfile!.defaultTeachableItemDurationInMinutes ?? 15;
    return items.where((item) => item.isIncludedInCourse).fold<int>(
          0,
          (sum, item) => sum + (item.durationInMinutes ?? defaultDuration),
        );
  }
}
