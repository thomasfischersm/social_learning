import 'package:social_learning/data/course_profile.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/learning_objective.dart';
import 'package:social_learning/data/session_plan.dart';
import 'package:social_learning/data/session_plan_activity.dart';
import 'package:social_learning/data/session_plan_block.dart';
import 'package:social_learning/data/teachable_item.dart';
import 'package:social_learning/data/teachable_item_category.dart';
import 'package:social_learning/data/teachable_item_tag.dart';

import 'package:social_learning/data/data_helpers/course_profile_functions.dart';
import 'package:social_learning/data/data_helpers/learning_objective_functions.dart';
import 'package:social_learning/data/data_helpers/teachable_item_functions.dart';
import 'package:social_learning/data/data_helpers/teachable_item_category_functions.dart';
import 'package:social_learning/data/data_helpers/teachable_item_tag_functions.dart';
import 'package:social_learning/data/data_helpers/session_plan_functions.dart';
import 'package:social_learning/data/data_helpers/session_plan_block_functions.dart';
import 'package:social_learning/data/data_helpers/session_plan_activity_functions.dart';

import '../../../data/data_helpers/reference_helper.dart';
import '../../../data/session_play_activity_type.dart';
import '../../../data/teachable_item_inclusion_status.dart';
import '../../../state/library_state.dart';

class SessionPlanContext {
  final String courseId;
  final LibraryState libraryState;
  final void Function() refresh;

  final List<LearningObjective> learningObjectives;
  final List<TeachableItem> items;
  final List<TeachableItemCategory> categories;
  final List<TeachableItemTag> tags;
  final CourseProfile? courseProfile;

  final SessionPlan sessionPlan;
  final List<SessionPlanBlock> blocks;
  final List<SessionPlanActivity> activities;

  final Map<String, TeachableItem> itemById = {};
  final Map<String, LearningObjective> objectiveById = {};
  final Map<String, TeachableItemCategory> categoryById = {};
  final Map<String, TeachableItemTag> tagById = {};
  final Map<String, SessionPlanBlock> blockById = {};
  final Map<String, SessionPlanActivity> activityById = {};

  bool isLoading = true;

  SessionPlanContext._({
    required this.courseId,
    required this.libraryState,
    required this.learningObjectives,
    required this.items,
    required this.categories,
    required this.tags,
    required this.courseProfile,
    required this.sessionPlan,
    required List<SessionPlanBlock> blocks,
    required List<SessionPlanActivity> activities,
    required this.refresh,
  })  : blocks = List.from(blocks),
        activities = List.from(activities) {
    // Build lookup maps
    itemById.addEntries(
        items.where((i) => i.id != null).map((i) => MapEntry(i.id!, i)));
    objectiveById.addEntries(learningObjectives
        .where((o) => o.id != null)
        .map((o) => MapEntry(o.id!, o)));
    categoryById.addEntries(
        categories.where((c) => c.id != null).map((c) => MapEntry(c.id!, c)));
    tagById.addEntries(
        tags.where((t) => t.id != null).map((t) => MapEntry(t.id!, t)));
    blockById.addEntries(
        this.blocks.where((b) => b.id != null).map((b) => MapEntry(b.id!, b)));
    activityById.addEntries(this
        .activities
        .where((a) => a.id != null)
        .map((a) => MapEntry(a.id!, a)));

    // Sort blocks by sortOrder
    this.blocks.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    // Sort activities by block.sortOrder, then by activity.sortOrder
    this.activities.sort((a, b) {
      final aBlockSort = blockById[a.sessionPlanBlockId.id]?.sortOrder ?? 0;
      final bBlockSort = blockById[b.sessionPlanBlockId.id]?.sortOrder ?? 0;
      final blockComparison = aBlockSort.compareTo(bBlockSort);
      return blockComparison != 0
          ? blockComparison
          : a.sortOrder.compareTo(b.sortOrder);
    });

    isLoading = false;
  }

  static Future<SessionPlanContext> create({
    required String courseId,
    required LibraryState libraryState,
    required void Function() refresh,
  }) async {
    final planFuture =
        SessionPlanFunctions.getOrCreateSessionPlanForCourse(courseId);
    final objectivesFuture =
        LearningObjectiveFunctions.getObjectivesForCourse(courseId);
    final profileFuture = CourseProfileFunctions.getCourseProfile(courseId);
    final categoriesFuture =
        TeachableItemCategoryFunctions.getCategoriesForCourse(courseId);
    final itemsFuture = TeachableItemFunctions.getItemsForCourse(courseId);
    final tagsFuture = TeachableItemTagFunctions.getTagsForCourse(courseId);

    final plan = await planFuture;

    final blockAndActivityFutures = await Future.wait([
      SessionPlanBlockFunctions.getBySessionPlan(plan.id!),
      SessionPlanActivityFunctions.getBySessionPlan(plan.id!),
    ]);

    final results = await Future.wait([
      objectivesFuture,
      profileFuture,
      categoriesFuture,
      itemsFuture,
      tagsFuture,
    ]);

    return SessionPlanContext._(
      courseId: courseId,
      libraryState: libraryState,
      learningObjectives: results[0] as List<LearningObjective>,
      courseProfile: results[1] as CourseProfile?,
      categories: results[2] as List<TeachableItemCategory>,
      items: results[3] as List<TeachableItem>,
      tags: results[4] as List<TeachableItemTag>,
      sessionPlan: plan,
      blocks: blockAndActivityFutures[0] as List<SessionPlanBlock>,
      activities: blockAndActivityFutures[1] as List<SessionPlanActivity>,
      refresh: refresh,
    );
  }

  List<Lesson>? get allLessons => libraryState.lessons;

  Lesson? getLessonByActivity(SessionPlanActivity activity) {
    if (activity.lessonId == null) {
      return null;
    }
    return libraryState.findLesson(activity.lessonId!.id);
  }

  double getCompletionForObjective(LearningObjective objective) {
    final lessonIdsFromObjective = <String>{};

    for (var teachableItemRef in objective.teachableItemRefs) {
      var teachableItem = itemById[teachableItemRef.id];
      if (teachableItem != null &&
          teachableItem.lessonRefs != null &&
          (teachableItem.inclusionStatus ==
                  TeachableItemInclusionStatus.includedAsPrerequisite ||
              teachableItem.inclusionStatus ==
                  TeachableItemInclusionStatus.explicitlyIncluded)) {
        for (final lessonRef in teachableItem.lessonRefs!) {
          lessonIdsFromObjective.add(lessonRef.id);
        }
      }
    }

    final lessonIdsInPlan = <String>{};

    for (var activity in activities) {
      if (activity.lessonId != null) {
        lessonIdsInPlan.add(activity.lessonId!.id);
      }
    }

    final matchedLessonCount =
        lessonIdsFromObjective.intersection(lessonIdsInPlan).length;
    final totalLessonCount = lessonIdsFromObjective.length;

    // Treat as complete if there are no lessons
    if (totalLessonCount == 0) return 1.0;

    return matchedLessonCount / totalLessonCount;
  }

  Future<void> moveBlock({
    required String blockId,
    required int newIndex,
  }) async {
    final oldIndex = blocks.indexWhere((b) => b.id == blockId);
    if (oldIndex < 0) {
      print('Block not found: $blockId');
      return;
    }

    // Allow placing at the end
    if (newIndex < 0 || newIndex > blocks.length) {
      print('Invalid newIndex: $newIndex');
      return;
    }

    // Move the block in the local list
    final block = blocks.removeAt(oldIndex);
    blocks.insert(newIndex, block);

    // Recalculate sortOrder
    final changedBlocks = <SessionPlanBlock>[];
    for (int i = 0; i < blocks.length; i++) {
      final b = blocks[i];
      if (b.sortOrder != i) {
        b.sortOrder = i;
        changedBlocks.add(b);
      }
    }

    // Batch update only changed blocks
    await SessionPlanBlockFunctions.batchUpdateSortOrders(changedBlocks);

    refresh();
  }

  Future<void> moveActivity({
    required String activityId,
    required String newBlockId,
    required int newIndex,
  }) async {
    final activity = activityById[activityId];
    if (activity == null) return;

    final oldBlockId = activity.sessionPlanBlockId.id;
    final isSameBlock = oldBlockId == newBlockId;

    if (newIndex < 0) return;

    // Build lists
    final oldBlockActivities = activities
        .where(
            (a) => a.sessionPlanBlockId.id == oldBlockId && a.id != activityId)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final newBlockActivities = isSameBlock
        ? oldBlockActivities
        : activities
            .where((a) => a.sessionPlanBlockId.id == newBlockId)
            .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    if (newIndex > newBlockActivities.length) return;

    // Insert the activity into the new block's list at the new index
    newBlockActivities.insert(newIndex, activity);

    // Change block ID only for the moved activity
    if (!isSameBlock) {
      activity.sessionPlanBlockId = docRef('sessionPlanBlocks', newBlockId);
    }

    final changedActivities = <SessionPlanActivity>[];

    // Update sortOrders and track changed ones (old block)
    if (!isSameBlock) {
      for (int i = 0; i < oldBlockActivities.length; i++) {
        final a = oldBlockActivities[i];
        if (a.sortOrder != i) {
          a.sortOrder = i;
          changedActivities.add(a);
        }
      }
    }

    // Update sortOrders and track changed ones (new block)
    for (int i = 0; i < newBlockActivities.length; i++) {
      final a = newBlockActivities[i];
      if (a.sortOrder != i || (a.id == activityId && !isSameBlock)) {
        a.sortOrder = i;
        changedActivities.add(a);
      }
    }

    await SessionPlanActivityFunctions.updateSortOrdersAndBlockChanges(
        changedActivities);

    // Sort global list
    activities.sort((a, b) {
      final blockA = blockById[a.sessionPlanBlockId.id];
      final blockB = blockById[b.sessionPlanBlockId.id];
      final orderA = blockA?.sortOrder ?? 0;
      final orderB = blockB?.sortOrder ?? 0;

      return orderA != orderB
          ? orderA.compareTo(orderB)
          : a.sortOrder.compareTo(b.sortOrder);
    });

    refresh();
  }

  Future<void> addBlock(String? name) async {
    final sortOrder = blocks.length;
    final newBlock = await SessionPlanBlockFunctions.create(
      courseId: courseId,
      sessionPlanId: sessionPlan.id!,
      name: name,
      sortOrder: sortOrder,
    );

    if (newBlock != null) {
      blocks.add(newBlock);
      blockById[newBlock.id!] = newBlock;
    }
    refresh();
  }

  Future<void> deleteBlock(String blockId) async {
    await SessionPlanBlockFunctions.delete(blockId);
    blocks.removeWhere((b) => b.id == blockId);
    blockById.remove(blockId);

    // Remove all activities in that block
    final activitiesToRemove =
        activities.where((a) => a.sessionPlanBlockId.id == blockId).toList();
    for (final a in activitiesToRemove) {
      activityById.remove(a.id);
      activities.remove(a);
    }

    refresh();
  }

  Future<void> addActivity({
    required String blockId,
    String? lessonId,
    String? name,
    String? notes,
    required SessionPlanActivityType activityType,
  }) async {
    final blockActivities = activities
        .where((a) => a.sessionPlanBlockId.id == blockId)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final sortOrder = blockActivities.length;

    final newActivity = await SessionPlanActivityFunctions.create(
      courseId: courseId,
      sessionPlanId: sessionPlan.id!,
      sessionPlanBlockId: blockId,
      sortOrder: sortOrder,
      lessonId: lessonId,
      name: name,
      notes: notes,
      activityType: activityType,
    );

    if (newActivity != null) {
      activities.add(newActivity);
      activityById[newActivity.id!] = newActivity;
    }
    refresh();
  }

  Future<void> deleteActivity(String activityId) async {
    await SessionPlanActivityFunctions.delete(activityId);
    activities.removeWhere((a) => a.id == activityId);
    activityById.remove(activityId);
    refresh();
  }

  Future<void> updateBlockName({
    required String blockId,
    required String newName,
  }) async {
    final block = blockById[blockId];
    if (block == null || block.name == newName) return;

    block.name = newName;
    await SessionPlanBlockFunctions.update(blockId: blockId, name: newName);
    refresh();
  }

  Future<void> updateActivity({
    required String activityId,
    String? name,
    SessionPlanActivityType? activityType,
    String? notes,
  }) async {
    final activity = activityById[activityId];
    if (activity == null) return;

    // Update in Firestore
    await SessionPlanActivityFunctions.update(
      activityId: activityId,
      name: name,
      activityType: activityType,
      notes: notes,
    );

    // Update in-memory model
    if (name != null) activity.name = name;
    if (activityType != null) activity.activityType = activityType;
    if (notes != null) activity.notes = notes;

    refresh();
  }

  Future<void> setLessonForActivity({
    required String activityId,
    required Lesson lesson,
  }) async {
    final updated = await SessionPlanActivityFunctions.update(
      activityId: activityId,
      lessonId: lesson.id,
    );

    if (updated != null) {
      // Replace the updated activity in the list
      final index = activities.indexWhere((a) => a.id == activityId);
      if (index != -1) {
        activities[index] = updated;
      }

      // Replace the updated activity in the map
      activityById[activityId] = updated;

      // Notify the refresh callback
      refresh();
    }
  }

  String getStartTimeStringForActivity(SessionPlanActivity activity) {
    final block = blockById[activity.sessionPlanBlockId.id];
    if (block == null) return '';

    final blockActivities = activities
        .where((a) => a.sessionPlanBlockId.id == block.id)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    int totalMinutes = 0;

    for (final a in blockActivities) {
      if (a.id == activity.id) break;
      totalMinutes += a.overrideDuration ??
          courseProfile?.defaultTeachableItemDurationInMinutes ??
          15;
    }

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours == 0) {
      return ':${minutes.toString().padLeft(2, '0')}';
    } else {
      return '$hours:${minutes.toString().padLeft(2, '0')}';
    }
  }

  String getStartTimeStringForNextActivity(String sessionPlanBlockId) {
    final block = blockById[sessionPlanBlockId];
    if (block == null) return '';

    final blockActivities = activities
        .where((a) => a.sessionPlanBlockId.id == block.id)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    int totalMinutes = 0;

    for (final a in blockActivities) {
      totalMinutes += a.overrideDuration ??
          courseProfile?.defaultTeachableItemDurationInMinutes ??
          15;
    }

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (hours == 0) {
      return ':${minutes.toString().padLeft(2, '0')}';
    } else {
      return '$hours:${minutes.toString().padLeft(2, '0')}';
    }
  }


  Future<void> updateActivityOverrideDuration({
    required String activityId,
    int? overrideDuration,
  }) async {
    final updated = await SessionPlanActivityFunctions.update(
      activityId: activityId,
      overrideDuration: overrideDuration,
    );

    if (updated == null) return;

    // Update local state
    final index = activities.indexWhere((a) => a.id == activityId);
    if (index != -1) {
      activities[index] = updated;
    }
    activityById[activityId] = updated;

    refresh(); // Notify listeners/UI
  }

  getActivitiesForBlock(String blockId) {
    return activities
        .where((a) => a.sessionPlanBlockId.id == blockId)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }
}
