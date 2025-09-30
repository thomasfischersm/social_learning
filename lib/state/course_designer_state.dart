import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/cloud_functions/cloud_functions.dart';
import 'package:social_learning/cloud_functions/inventory_generation_response.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/course_profile.dart';
import 'package:social_learning/data/data_helpers/course_profile_functions.dart';
import 'package:social_learning/data/data_helpers/learning_objective_functions.dart';
import 'package:social_learning/data/data_helpers/teachable_item_category_functions.dart';
import 'package:social_learning/data/data_helpers/teachable_item_functions.dart';
import 'package:social_learning/data/data_helpers/teachable_item_tag_functions.dart';
import 'package:social_learning/data/data_helpers/session_plan_functions.dart';
import 'package:social_learning/data/data_helpers/session_plan_block_functions.dart';
import 'package:social_learning/data/data_helpers/session_plan_activity_functions.dart';
import 'package:social_learning/data/learning_objective.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/session_plan.dart';
import 'package:social_learning/data/session_plan_activity.dart';
import 'package:social_learning/data/session_plan_block.dart';
import 'package:social_learning/data/session_play_activity_type.dart';
import 'package:social_learning/data/teachable_item.dart';
import 'package:social_learning/data/teachable_item_category.dart';
import 'package:social_learning/data/teachable_item_inclusion_status.dart';
import 'package:social_learning/data/teachable_item_tag.dart';
import 'package:social_learning/data/skill_rubric.dart';
import 'package:social_learning/data/data_helpers/skill_rubrics_functions.dart';
import 'package:social_learning/data/data_helpers/reference_helper.dart';
import 'package:social_learning/state/library_state.dart';

class CourseDesignerState extends ChangeNotifier {
  final LibraryState _libraryState;

  Course? _activeCourse;
  CourseDesignerStateStatus _status = CourseDesignerStateStatus.uninitialized;
  Completer<void> _initCompleter = Completer<void>();

  CourseProfile? courseProfile;
  List<TeachableItemCategory> categories = [];
  List<TeachableItem> items = [];
  List<TeachableItemTag> tags = [];
  List<LearningObjective> learningObjectives = [];
  SessionPlan? sessionPlan;
  List<SessionPlanBlock> blocks = [];
  List<SessionPlanActivity> activities = [];
  SkillRubric? skillRubric;

  final Map<String, TeachableItem> itemById = {};
  final Map<String, LearningObjective> objectiveById = {};
  final Map<String, TeachableItemCategory> categoryById = {};
  final Map<String, TeachableItemTag> tagById = {};
  final Map<String, SessionPlanBlock> blockById = {};
  final Map<String, SessionPlanActivity> activityById = {};

  final Set<String> requiredItemIds = {};
  final Set<String> recommendedItemIds = {};

  CourseDesignerState(this._libraryState) {
    _libraryState.addListener(_onLibraryStateChanged);
  }

  CourseDesignerStateStatus get status => _status;

  Course? get course => _activeCourse;

  Future<void> ensureInitialized() async {
    await _ensureInitialized();
  }

  Future<void> _ensureInitialized() async {
    if (_status == CourseDesignerStateStatus.uninitialized) {
      _status = CourseDesignerStateStatus.initializing;

      await _libraryState.initialize();
      await _initialize();
    }

    return _initCompleter.future;
  }

  Future<void> _initialize() async {
    _activeCourse = _libraryState.selectedCourse;
    var selectedCourseId = _activeCourse?.id;
    if (selectedCourseId != null) {
      await _loadDataForCourse(selectedCourseId);
      _status = CourseDesignerStateStatus.initialized;
      _initCompleter.complete();
      notifyListeners();
    }
  }

  Future<void> _loadDataForCourse(String courseId) async {
    print('Loading course data for courseId: $courseId');
    final planFuture =
        SessionPlanFunctions.getOrCreateSessionPlanForCourse(courseId);
    final objectivesFuture =
        LearningObjectiveFunctions.getObjectivesForCourse(courseId);
    final profileFuture = CourseProfileFunctions.getCourseProfile(courseId);
    final categoriesFuture =
        TeachableItemCategoryFunctions.getCategoriesForCourse(courseId);
    final itemsFuture = TeachableItemFunctions.getItemsForCourse(courseId);
    final tagsFuture = TeachableItemTagFunctions.getTagsForCourse(courseId);
    final rubricFuture = SkillRubricsFunctions.ensureRubricForCourse(courseId);

    SessionPlan plan;
    try {
      plan = await planFuture;
    } on FirebaseException catch (e) {
      print(
          'Error retrieving session plan for course $courseId: ${e.code} ${e.message}');
      rethrow;
    }

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
      rubricFuture,
    ]);

    learningObjectives = results[0] as List<LearningObjective>;
    courseProfile = results[1] as CourseProfile?;
    categories = results[2] as List<TeachableItemCategory>;
    items = results[3] as List<TeachableItem>;
    tags = results[4] as List<TeachableItemTag>;
    skillRubric = results[5] as SkillRubric?;
    sessionPlan = plan;
    blocks = List.from(blockAndActivityFutures[0] as List<SessionPlanBlock>);
    activities =
        List.from(blockAndActivityFutures[1] as List<SessionPlanActivity>);

    _postProcessMaps();
  }

  void _postProcessMaps() {
    itemById
      ..clear()
      ..addEntries(
          items.where((i) => i.id != null).map((i) => MapEntry(i.id!, i)));
    objectiveById
      ..clear()
      ..addEntries(learningObjectives
          .where((o) => o.id != null)
          .map((o) => MapEntry(o.id!, o)));
    categoryById
      ..clear()
      ..addEntries(
          categories.where((c) => c.id != null).map((c) => MapEntry(c.id!, c)));
    tagById
      ..clear()
      ..addEntries(
          tags.where((t) => t.id != null).map((t) => MapEntry(t.id!, t)));
    blockById
      ..clear()
      ..addEntries(
          blocks.where((b) => b.id != null).map((b) => MapEntry(b.id!, b)));
    activityById
      ..clear()
      ..addEntries(
          activities.where((a) => a.id != null).map((a) => MapEntry(a.id!, a)));

    blocks.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    activities.sort((a, b) {
      final aBlockSort = blockById[a.sessionPlanBlockId.id]?.sortOrder ?? 0;
      final bBlockSort = blockById[b.sessionPlanBlockId.id]?.sortOrder ?? 0;
      final blockComparison = aBlockSort.compareTo(bBlockSort);
      return blockComparison != 0
          ? blockComparison
          : a.sortOrder.compareTo(b.sortOrder);
    });

    _initRequireRecommendedItemIds();
    _updateInclusionStatuses();
  }

  Future<void> _onLibraryStateChanged() async {
    if (_activeCourse != _libraryState.selectedCourse) {
      if (_libraryState.selectedCourse != null) {
        if (_status == CourseDesignerStateStatus.initializing) {
          // Abort due to concurrent initialization
          return;
        }

        _status = CourseDesignerStateStatus.initializing;
        _initCompleter = Completer<void>();
        await _initialize();
      } else {
        _status = CourseDesignerStateStatus.noCourseSelected;
        clear();
      }
    }
  }

  void signOut() {
    _activeCourse = null;
    _status = CourseDesignerStateStatus.uninitialized;
    _initCompleter = Completer<void>();
    clear();
  }

  void clear() {
    _activeCourse = _libraryState.selectedCourse;
    courseProfile = null;
    categories.clear();
    items.clear();
    tags.clear();
    learningObjectives.clear();
    sessionPlan = null;
    blocks.clear();
    activities.clear();
    skillRubric = null;
    itemById.clear();
    objectiveById.clear();
    categoryById.clear();
    tagById.clear();
    blockById.clear();
    activityById.clear();
    requiredItemIds.clear();
    recommendedItemIds.clear();
    notifyListeners();
  }

  // ----- Skill Rubrics -----
  Future<void> addSkillDimension(String name, {String? description}) async {
    await _ensureInitialized();
    if (_activeCourse == null) return;
    final updated = await SkillRubricsFunctions.createDimension(
      courseId: _activeCourse!.id!,
      name: name,
      description: description,
    );
    if (updated != null) {
      skillRubric = updated;
      notifyListeners();
    }
  }

  Future<void> addSkillDegree(String dimensionId, String name,
      {String? description}) async {
    await _ensureInitialized();
    if (_activeCourse == null) return;
    final updated = await SkillRubricsFunctions.addDegree(
      courseId: _activeCourse!.id!,
      dimensionId: dimensionId,
      name: name,
      description: description,
    );
    if (updated != null) {
      skillRubric = updated;
      notifyListeners();
    }
  }

  Future<void> updateSkillDimension(
      {required String dimensionId,
      required String name,
      String? description}) async {
    await _ensureInitialized();
    if (_activeCourse == null) return;
    final updated = await SkillRubricsFunctions.updateDimension(
      courseId: _activeCourse!.id!,
      dimensionId: dimensionId,
      name: name,
      description: description,
    );
    if (updated != null) {
      skillRubric = updated;
      notifyListeners();
    }
  }

  Future<void> updateSkillDegree(
      {required String dimensionId,
      required String degreeId,
      required String name,
      String? description}) async {
    await _ensureInitialized();
    if (_activeCourse == null) return;
    final updated = await SkillRubricsFunctions.updateDegree(
      courseId: _activeCourse!.id!,
      dimensionId: dimensionId,
      degreeId: degreeId,
      name: name,
      description: description,
    );
    if (updated != null) {
      skillRubric = updated;
      notifyListeners();
    }
  }

  Future<void> moveSkillDimension(
      {required String dimensionId, required int newIndex}) async {
    await _ensureInitialized();
    if (_activeCourse == null) return;
    final updated = await SkillRubricsFunctions.moveDimension(
      courseId: _activeCourse!.id!,
      dimensionId: dimensionId,
      newIndex: newIndex,
    );
    if (updated != null) {
      skillRubric = updated;
      notifyListeners();
    }
  }

  Future<void> moveSkillDegree(
      {required String dimensionId,
      required String degreeId,
      required int newIndex}) async {
    await _ensureInitialized();
    if (_activeCourse == null) return;
    final updated = await SkillRubricsFunctions.moveDegree(
      courseId: _activeCourse!.id!,
      dimensionId: dimensionId,
      degreeId: degreeId,
      newIndex: newIndex,
    );
    if (updated != null) {
      skillRubric = updated;
      notifyListeners();
    }
  }

  Future<void> moveSkillLesson({
    required String fromDegreeId,
    required int fromLessonIndex,
    required String toDegreeId,
    required int toLessonIndex,
  }) async {
    await _ensureInitialized();
    if (_activeCourse == null || skillRubric == null) return;
    final updated = await SkillRubricsFunctions.moveLessonByDegree(
      rubric: skillRubric!,
      fromDegreeId: fromDegreeId,
      fromLessonIndex: fromLessonIndex,
      toDegreeId: toDegreeId,
      toLessonIndex: toLessonIndex,
    );
    if (updated != null) {
      skillRubric = updated;
      notifyListeners();
    }
  }

  Future<void> deleteSkillDegree(
      {required String dimensionId, required String degreeId}) async {
    await _ensureInitialized();
    if (_activeCourse == null) return;
    final updated = await SkillRubricsFunctions.removeDegree(
      courseId: _activeCourse!.id!,
      dimensionId: dimensionId,
      degreeId: degreeId,
    );
    if (updated != null) {
      skillRubric = updated;
      notifyListeners();
    }
  }

  Future<void> deleteSkillDimension(String dimensionId) async {
    await _ensureInitialized();
    if (_activeCourse == null) return;
    final updated = await SkillRubricsFunctions.removeDimension(
      courseId: _activeCourse!.id!,
      dimensionId: dimensionId,
    );
    if (updated != null) {
      skillRubric = updated;
      notifyListeners();
    }
  }

  Future<void> addLessonToSkillDegree(
      {required String degreeId, required String lessonId}) async {
    await _ensureInitialized();
    if (_activeCourse == null) return;
    final updated = await SkillRubricsFunctions.addLessonByDegreeId(
      courseId: _activeCourse!.id!,
      degreeId: degreeId,
      lessonId: lessonId,
    );
    if (updated != null) {
      skillRubric = updated;
      notifyListeners();
    }
  }

  Future<void> generateSkillRubric() async {
    await _ensureInitialized();
    if (_activeCourse == null) return;
    var originalStatus = _status;
    _status = CourseDesignerStateStatus.waitingOnAI;
    notifyListeners();
    try {
      final response = await CloudFunctions.generateSkillRubric(
        _activeCourse!,
        courseProfile,
      );
      final updated = await SkillRubricsFunctions.replaceRubricForCourse(
        courseId: _activeCourse!.id!,
        generated: response.dimensions,
      );
      if (updated != null) {
        skillRubric = updated;
      }
    } catch (e) {
      // ignore
    }
    _status = originalStatus;
    notifyListeners();
  }

  // ----- Inventory / Item management -----
  Future<void> addNewItem(TeachableItemCategory category, String name) async {
    await _ensureInitialized();
    final newItem = await TeachableItemFunctions.addItem(
      courseId: _activeCourse!.id!,
      categoryId: category.id!,
      name: name,
    );
    if (newItem == null) return;
    items.add(newItem);
    itemById[newItem.id!] = newItem;
    notifyListeners();
  }

  Future<void> addNewCategory(String name) async {
    await _ensureInitialized();
    final newCategory = await TeachableItemCategoryFunctions.addCategory(
      courseId: _activeCourse!.id!,
      name: name,
    );
    if (newCategory == null) return;
    categories.add(newCategory);
    categoryById[newCategory.id!] = newCategory;
    notifyListeners();
  }

  Future<void> deleteItem(TeachableItem item) async {
    await _ensureInitialized();
    await TeachableItemFunctions.deleteItem(itemId: item.id!);
    items.removeWhere((i) => i.id == item.id);
    itemById.remove(item.id);
    notifyListeners();
  }

  Future<void> deleteCategory(TeachableItemCategory category) async {
    await _ensureInitialized();
    await TeachableItemCategoryFunctions.deleteCategory(
        categoryId: category.id!);
    categories.removeWhere((c) => c.id == category.id);
    categoryById.remove(category.id);
    items.removeWhere((i) => i.categoryId.id == category.id);
    notifyListeners();
  }

  Future<void> updateCategorySortOrder({
    required TeachableItemCategory movedCategory,
    required int newIndex,
  }) async {
    await _ensureInitialized();
    await TeachableItemCategoryFunctions.updateCategorySortOrder(
      movedCategory: movedCategory,
      newIndex: newIndex,
      allCategoriesForCourse: categories,
    );

    categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final currentIndex = categories.indexWhere((c) => c.id == movedCategory.id);
    if (currentIndex == -1) return;

    final moved = categories.removeAt(currentIndex);
    categories.insert(newIndex, moved);

    for (int i = 0; i < categories.length; i++) {
      final cat = categories[i];
      if (cat.sortOrder != i) {
        final updated = TeachableItemCategory(
          id: cat.id,
          courseId: cat.courseId,
          name: cat.name,
          sortOrder: i,
          createdAt: cat.createdAt,
          modifiedAt: cat.modifiedAt,
        );
        categories[i] = updated;
        categoryById[cat.id!] = updated;
      }
    }
    notifyListeners();
  }

  Future<void> updateItemSortOrder({
    required TeachableItem movedItem,
    required DocumentReference newCategoryRef,
    required int newIndex,
  }) async {
    await _ensureInitialized();
    await TeachableItemFunctions.updateItemSortOrder(
      allItemsAcrossCategories: items,
      movedItem: movedItem,
      newCategoryRef: newCategoryRef,
      newIndex: newIndex,
    );

    final sourceCategoryId = movedItem.categoryId.id;
    final destinationCategoryId = newCategoryRef.id;
    final sameCategory = sourceCategoryId == destinationCategoryId;

    if (sameCategory) {
      final categoryItems = items
          .where((i) => i.categoryId.id == sourceCategoryId)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      final currentIndex =
          categoryItems.indexWhere((i) => i.id == movedItem.id);
      if (currentIndex == -1) return;
      final moved = categoryItems.removeAt(currentIndex);
      categoryItems.insert(newIndex, moved);

      for (int i = 0; i < categoryItems.length; i++) {
        final item = categoryItems[i];
        final updated = TeachableItem(
          id: item.id,
          courseId: item.courseId,
          categoryId: item.categoryId,
          name: item.name,
          notes: item.notes,
          sortOrder: i,
          durationInMinutes: item.durationInMinutes,
          tagIds: item.tagIds,
          requiredPrerequisiteIds: item.requiredPrerequisiteIds,
          recommendedPrerequisiteIds: item.recommendedPrerequisiteIds,
          lessonRefs: item.lessonRefs,
          inclusionStatus: item.inclusionStatus,
          createdAt: item.createdAt,
          modifiedAt: item.modifiedAt,
        );
        final globalIndex = items.indexWhere((it) => it.id == item.id);
        if (globalIndex != -1) items[globalIndex] = updated;
        itemById[item.id!] = updated;
      }
    } else {
      final sourceItems = items
          .where((i) =>
              i.categoryId.id == sourceCategoryId && i.id != movedItem.id)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      for (int i = 0; i < sourceItems.length; i++) {
        final item = sourceItems[i];
        if (item.sortOrder != i) {
          final updated = TeachableItem(
            id: item.id,
            courseId: item.courseId,
            categoryId: item.categoryId,
            name: item.name,
            notes: item.notes,
            sortOrder: i,
            durationInMinutes: item.durationInMinutes,
            tagIds: item.tagIds,
            requiredPrerequisiteIds: item.requiredPrerequisiteIds,
            recommendedPrerequisiteIds: item.recommendedPrerequisiteIds,
            lessonRefs: item.lessonRefs,
            inclusionStatus: item.inclusionStatus,
            createdAt: item.createdAt,
            modifiedAt: item.modifiedAt,
          );
          final globalIndex = items.indexWhere((it) => it.id == item.id);
          if (globalIndex != -1) items[globalIndex] = updated;
          itemById[item.id!] = updated;
        }
      }

      final destItems = items
          .where((i) => i.categoryId.id == destinationCategoryId)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      destItems.insert(newIndex, movedItem);
      for (int i = 0; i < destItems.length; i++) {
        final item = destItems[i];
        final isMoved = item.id == movedItem.id;
        final updated = TeachableItem(
          id: item.id,
          courseId: item.courseId,
          categoryId: isMoved ? newCategoryRef : item.categoryId,
          name: item.name,
          notes: item.notes,
          sortOrder: i,
          durationInMinutes: item.durationInMinutes,
          tagIds: item.tagIds,
          requiredPrerequisiteIds: item.requiredPrerequisiteIds,
          recommendedPrerequisiteIds: item.recommendedPrerequisiteIds,
          lessonRefs: item.lessonRefs,
          inclusionStatus: item.inclusionStatus,
          createdAt: item.createdAt,
          modifiedAt: item.modifiedAt,
        );
        final globalIndex = items.indexWhere((it) => it.id == item.id);
        if (globalIndex != -1) {
          items[globalIndex] = updated;
        } else {
          items.add(updated);
        }
        itemById[item.id!] = updated;
      }
    }
    notifyListeners();
  }

  Future<void> generateInventory() async {
    await _ensureInitialized();
    if (_activeCourse == null) return;

    var originalStatus = _status;
    _status = CourseDesignerStateStatus.waitingOnAI;
    notifyListeners();
    try {
      final response = await CloudFunctions.generateCourseInventory(
        _activeCourse!,
        courseProfile,
      );
      await _saveGeneratedInventory(response.categories);
    } catch (e) {
      // ignore
    }
    await _loadDataForCourse(_activeCourse!.id!);
    _status = originalStatus;
    notifyListeners();
  }

  Future<void> _saveGeneratedInventory(
      List<GeneratedCategory> generated) async {
    final categoryNames = generated.map((e) => e.category).toList();
    final newCategories =
        await TeachableItemCategoryFunctions.bulkCreateCategories(
      courseId: _activeCourse!.id!,
      names: categoryNames,
    );
    final courseRef = docRef('courses', _activeCourse!.id!);
    final itemsToCreate = <TeachableItem>[];
    for (int i = 0; i < newCategories.length; i++) {
      final cat = newCategories[i];
      final catRef = docRef('teachableItemCategories', cat.id!);
      final names = generated[i].items;
      for (int j = 0; j < names.length; j++) {
        itemsToCreate.add(
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

    await TeachableItemFunctions.bulkCreateItems(itemsToCreate);
  }

  // ----- Learning Objectives -----
  Future<void> addObjective(String name) async {
    await _ensureInitialized();
    int sortOrder = learningObjectives.isEmpty
        ? 0
        : learningObjectives
                .map((o) => o.sortOrder)
                .reduce((a, b) => a > b ? a : b) +
            1;
    final objective = await LearningObjectiveFunctions.addObjective(
      courseId: _activeCourse!.id!,
      name: name,
      sortOrder: sortOrder,
    );
    learningObjectives.add(objective);
    objectiveById[objective.id!] = objective;
    notifyListeners();
  }

  Future<void> updateObjective(
      {required String id, required String name, String? description}) async {
    await _ensureInitialized();
    final objective = await LearningObjectiveFunctions.updateObjective(
      id: id,
      name: name,
      description: description,
    );
    final index = learningObjectives.indexWhere((o) => o.id == id);
    if (index != -1) {
      learningObjectives[index] = objective;
    }
    objectiveById[id] = objective;
    notifyListeners();
  }

  Future<void> deleteObjective(LearningObjective objective) async {
    await _ensureInitialized();
    await LearningObjectiveFunctions.deleteObjective(objective);
    learningObjectives.removeWhere((o) => o.id == objective.id);
    objectiveById.remove(objective.id);
    notifyListeners();
  }

  Future<void> addLessonToTeachableItem(
      {required TeachableItem item, required Lesson lesson}) async {
    await _ensureInitialized();
    final updated = await TeachableItemFunctions.addLessonToTeachableItem(
      itemId: item.id!,
      lessonId: lesson.id!,
    );
    if (updated != null) {
      itemById[item.id!] = updated;
      final idx = items.indexWhere((i) => i.id == item.id);
      if (idx != -1) items[idx] = updated;
      notifyListeners();
    }
  }

  Future<void> replaceLessonForTeachableItem({
    required TeachableItem item,
    required Lesson oldLesson,
    required Lesson newLesson,
  }) async {
    await _ensureInitialized();
    final updated = await TeachableItemFunctions.replaceLessonOnItem(
      itemId: item.id!,
      oldLessonId: oldLesson.id!,
      newLessonId: newLesson.id!,
    );
    if (updated != null) {
      itemById[item.id!] = updated;
      final idx = items.indexWhere((i) => i.id == item.id);
      if (idx != -1) items[idx] = updated;
      notifyListeners();
    }
  }

  Future<void> removeLessonFromTeachableItem(
      {required TeachableItem item, required Lesson lesson}) async {
    await _ensureInitialized();
    final updated = await TeachableItemFunctions.removeLessonFromTeachableItem(
      itemId: item.id!,
      lessonId: lesson.id!,
    );
    if (updated != null) {
      itemById[item.id!] = updated;
      final idx = items.indexWhere((i) => i.id == item.id);
      if (idx != -1) items[idx] = updated;
      notifyListeners();
    }
  }

  Future<void> addTeachableItemToObjective(
      {required LearningObjective objective,
      required TeachableItem item}) async {
    await _ensureInitialized();
    final updated = await LearningObjectiveFunctions.addItemToObjective(
      objectiveId: objective.id!,
      teachableItemId: item.id!,
    );
    if (updated != null) {
      final idx = learningObjectives.indexWhere((o) => o.id == objective.id);
      if (idx != -1) {
        learningObjectives[idx] = updated;
      }
      objectiveById[objective.id!] = updated;
    }

    // Ensure the teachable item is explicitly selected if not already included.
    if (item.inclusionStatus !=
            TeachableItemInclusionStatus.explicitlyIncluded &&
        item.inclusionStatus !=
            TeachableItemInclusionStatus.includedAsPrerequisite) {
      item.inclusionStatus = TeachableItemInclusionStatus.explicitlyIncluded;
      await TeachableItemFunctions.updateInclusionStatus(item);
      itemById[item.id!] = item;
      final idx = items.indexWhere((i) => i.id == item.id);
      if (idx != -1) items[idx] = item;
    }

    notifyListeners();
  }

  Future<void> replaceTeachableItemInObjective({
    required LearningObjective objective,
    required TeachableItem oldItem,
    required TeachableItem newItem,
  }) async {
    await _ensureInitialized();
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
      objectiveById[objective.id!] = updated;
      notifyListeners();
    }
  }

  Future<void> removeTeachableItemFromObjective(
      {required LearningObjective objective,
      required TeachableItem item}) async {
    await _ensureInitialized();
    final updated = await LearningObjectiveFunctions.removeItemFromObjective(
      objectiveId: objective.id!,
      teachableItemId: item.id!,
    );
    if (updated != null) {
      final idx = learningObjectives.indexWhere((o) => o.id == objective.id);
      if (idx != -1) {
        learningObjectives[idx] = updated;
      }
      objectiveById[objective.id!] = updated;
      notifyListeners();
    }
  }

  // ----- Prerequisites -----
  List<TeachableItem> getRequiredPrerequisites(TeachableItem item) {
    _ensureInitialized();
    return _sortedPrerequisites(item.requiredPrerequisiteIds ?? []);
  }

  List<TeachableItem> getRecommendedPrerequisites(TeachableItem item) {
    _ensureInitialized();
    return _sortedPrerequisites(item.recommendedPrerequisiteIds ?? []);
  }

  List<TeachableItem> getAllPrerequisites(TeachableItem item) {
    final required = getRequiredPrerequisites(item);
    final recommended = getRecommendedPrerequisites(item);
    return [...required, ...recommended];
  }

  List<TeachableItem> getItemsWithDependencies() {
    _ensureInitialized();
    final filtered = items.where((item) {
      final hasRequired = item.requiredPrerequisiteIds?.isNotEmpty ?? false;
      final hasRecommended =
          item.recommendedPrerequisiteIds?.isNotEmpty ?? false;
      return hasRequired || hasRecommended;
    }).toList();
    filtered.sort(_itemSortComparator);
    return filtered;
  }

  Future<void> addDependency(
      {required TeachableItem target,
      required TeachableItem dependency,
      required bool required}) async {
    await _ensureInitialized();
    final updated = await TeachableItemFunctions.addDependency(
      target: target,
      dependency: dependency,
      required: required,
    );
    _updateItemInContext(updated);
  }

  Future<void> removeDependency(
      {required TeachableItem target,
      required TeachableItem dependency}) async {
    await _ensureInitialized();
    final updated = await TeachableItemFunctions.removeDependency(
      target: target,
      dependency: dependency,
    );
    _updateItemInContext(updated);
  }

  Future<void> toggleDependency(
      {required TeachableItem target,
      required TeachableItem dependency}) async {
    await _ensureInitialized();
    final updated = await TeachableItemFunctions.toggleDependency(
      target: target,
      dependency: dependency,
    );
    _updateItemInContext(updated);
  }

  List<TeachableItemTag> getTagsForItem(TeachableItem item) {
    final refs = item.tagIds ?? [];
    return refs
        .map((ref) => tagById[ref.id])
        .where((tag) => tag != null)
        .cast<TeachableItemTag>()
        .toList();
  }

  List<TeachableItem> _sortedPrerequisites(List<dynamic> prereqRefs) {
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
    notifyListeners();
  }

  Map<String, List<TeachableItem>> get itemsGroupedByCategory {
    final Map<String, List<TeachableItem>> map = {};
    for (final item in items) {
      final categoryId = item.categoryId.id;
      map.putIfAbsent(categoryId, () => []);
      map[categoryId]!.add(item);
    }
    for (final itemList in map.values) {
      itemList.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }
    return map;
  }

  // ----- Scope management -----
  void _initRequireRecommendedItemIds() {
    requiredItemIds.clear();
    recommendedItemIds.clear();

    final explicitlySelectedItems = items
        .where((item) =>
            item.inclusionStatus ==
            TeachableItemInclusionStatus.explicitlyIncluded)
        .toSet();

    Set<TeachableItem> requiredItemsToVisit = {};
    Set<TeachableItem> recommendedItemsToVisit = {};

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

    while (
        requiredItemsToVisit.isNotEmpty || recommendedItemsToVisit.isNotEmpty) {
      if (requiredItemsToVisit.isNotEmpty) {
        final item = requiredItemsToVisit.first;
        requiredItemsToVisit.remove(item);
        if (item.inclusionStatus ==
            TeachableItemInclusionStatus.explicitlyExcluded) {
          continue;
        }
        requiredItemIds.add(item.id!);
        recommendedItemIds.remove(item.id!);
        recommendedItemsToVisit.remove(item);
        if (item.requiredPrerequisiteIds != null) {
          for (var ref in item.requiredPrerequisiteIds!) {
            final requiredItem = itemById[ref.id];
            if ((requiredItem != null) &&
                (!requiredItemIds.contains(requiredItem.id!))) {
              requiredItemsToVisit.add(requiredItem);
            }
          }
        }
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
        final item = recommendedItemsToVisit.first;
        recommendedItemsToVisit.remove(item);
        if (item.inclusionStatus ==
            TeachableItemInclusionStatus.explicitlyExcluded) {
          continue;
        }
        if (requiredItemIds.contains(item.id!)) {
          continue;
        }
        recommendedItemIds.add(item.id!);
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
  }

  void _updateInclusionStatuses() {
    Set<TeachableItem> needToSelect = {};
    Set<TeachableItem> needToDeselect = {};

    for (final item in items) {
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

    TeachableItemFunctions.updateInclusionStatuses(
        needToSelect, needToDeselect);

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

  Future<void> saveInstructionalPercentage(int instructionalPercent) async {
    if (courseProfile == null) return;
    courseProfile!.instructionalTimePercent = instructionalPercent;
    await CourseProfileFunctions.saveCourseProfile(courseProfile!);
    notifyListeners();
  }

  void saveSessionDuration(
      int? sessionCount, int? sessionDuration, int? totalMinutes) {
    if (courseProfile == null) return;
    courseProfile!.sessionCount = sessionCount;
    courseProfile!.sessionDurationInMinutes = sessionDuration;
    courseProfile!.totalCourseDurationInMinutes = totalMinutes;
    CourseProfileFunctions.saveCourseProfile(courseProfile!);
    notifyListeners();
  }

  void saveDefaultTeachableItemDuration(int newDuration) {
    if (courseProfile == null) return;
    courseProfile!.defaultTeachableItemDurationInMinutes = newDuration;
    CourseProfileFunctions.saveCourseProfile(courseProfile!);
    notifyListeners();
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
        .fold<int>(0,
            (sum, item) => sum + (item.durationInMinutes ?? defaultDuration));
  }

  Future<void> toggleItemInclusionStatus(TeachableItem item) async {
    switch (item.inclusionStatus) {
      case TeachableItemInclusionStatus.excluded:
        item.inclusionStatus = TeachableItemInclusionStatus.explicitlyIncluded;
        break;
      case TeachableItemInclusionStatus.includedAsPrerequisite:
        item.inclusionStatus = TeachableItemInclusionStatus.explicitlyExcluded;
        break;
      case TeachableItemInclusionStatus.explicitlyIncluded:
        item.inclusionStatus = TeachableItemInclusionStatus.excluded;
        break;
      case TeachableItemInclusionStatus.explicitlyExcluded:
        item.inclusionStatus = TeachableItemInclusionStatus.excluded;
        break;
      default:
        return;
    }
    await TeachableItemFunctions.updateInclusionStatus(item);
    _initRequireRecommendedItemIds();
    _updateInclusionStatuses();
    notifyListeners();
  }

  Future<void> saveItemDurationOverride(
      TeachableItem item, int? newDurationOverride) async {
    if (item.durationInMinutes == newDurationOverride) {
      return;
    }
    item.durationInMinutes = newDurationOverride;
    await TeachableItemFunctions.updateDurationOverride(
        item, newDurationOverride);
    notifyListeners();
  }

  // ----- Session Plan -----
  List<Lesson>? get allLessons => _libraryState.lessons;

  Lesson? getLessonByActivity(SessionPlanActivity activity) {
    if (activity.lessonId == null) {
      return null;
    }
    return _libraryState.findLesson(activity.lessonId!.id);
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
    if (totalLessonCount == 0) return 1.0;
    return matchedLessonCount / totalLessonCount;
  }

  Future<void> moveBlockBefore(
      {required String fromBlockId, required String? beforeBlockId}) async {
    await moveBlock(
        blockId: fromBlockId,
        newIndex: (beforeBlockId == null)
            ? blocks.length
            : blocks.indexWhere((b) => b.id == beforeBlockId));
  }

  Future<void> moveBlock(
      {required String blockId, required int newIndex}) async {
    final oldIndex = blocks.indexWhere((b) => b.id == blockId);
    if (oldIndex < 0) return;
    if (newIndex < 0 || newIndex > blocks.length) return;
    final block = blocks.removeAt(oldIndex);
    blocks.insert(newIndex, block);
    final changedBlocks = <SessionPlanBlock>[];
    for (int i = 0; i < blocks.length; i++) {
      final b = blocks[i];
      if (b.sortOrder != i) {
        b.sortOrder = i;
        changedBlocks.add(b);
      }
    }
    await SessionPlanBlockFunctions.batchUpdateSortOrders(changedBlocks);
    notifyListeners();
  }

  Future<void> moveActivity3(
      {required String activityId,
      required String fromBlockId,
      required String toBlockId,
      required String? beforeActivityId}) async {
    final activity = activityById[activityId];
    if (activity == null) return;

    final sameBlock = fromBlockId == toBlockId;

    final srcActivities = activities
        .where(
            (a) => a.sessionPlanBlockId.id == fromBlockId && a.id != activityId)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final destActivities = sameBlock
        ? srcActivities
        : activities.where((a) => a.sessionPlanBlockId.id == toBlockId).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final destIndex = (beforeActivityId == null)
        ? destActivities.length
        : destActivities
            .indexWhere((a) => a.id == beforeActivityId)
            .clamp(0, destActivities.length);

    destActivities.insert(destIndex, activity);

    if (!sameBlock) {
      activity.sessionPlanBlockId = docRef('sessionPlanBlocks', toBlockId);
    }

    final changed = <SessionPlanActivity>[];

    void syncSortOrders(List<SessionPlanActivity> list) {
      for (var i = 0; i < list.length; i++) {
        if (list[i].sortOrder != i) {
          list[i].sortOrder = i;
          changed.add(list[i]);
        }
      }
    }

    syncSortOrders(destActivities);
    if (!sameBlock) syncSortOrders(srcActivities);

    if (changed.isNotEmpty) {
      await SessionPlanActivityFunctions.updateSortOrdersAndBlockChanges(
          changed);
    }

    activities.sort((a, b) {
      final orderA = blockById[a.sessionPlanBlockId.id]?.sortOrder ?? 0;
      final orderB = blockById[b.sessionPlanBlockId.id]?.sortOrder ?? 0;
      return orderA != orderB
          ? orderA.compareTo(orderB)
          : a.sortOrder.compareTo(b.sortOrder);
    });

    notifyListeners();
  }

  Future<void> moveActivity(
      {required String activityId,
      required String newBlockId,
      required int newIndex}) async {
    final activity = activityById[activityId];
    if (activity == null) return;
    final oldBlockId = activity.sessionPlanBlockId.id;
    final isSameBlock = oldBlockId == newBlockId;
    if (newIndex < 0) return;

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

    newBlockActivities.insert(newIndex, activity);

    if (!isSameBlock) {
      activity.sessionPlanBlockId = docRef('sessionPlanBlocks', newBlockId);
    }

    final changedActivities = <SessionPlanActivity>[];

    if (!isSameBlock) {
      for (int i = 0; i < oldBlockActivities.length; i++) {
        final a = oldBlockActivities[i];
        if (a.sortOrder != i) {
          a.sortOrder = i;
          changedActivities.add(a);
        }
      }
    }

    for (int i = 0; i < newBlockActivities.length; i++) {
      final a = newBlockActivities[i];
      if (a.sortOrder != i || (a.id == activityId && !isSameBlock)) {
        a.sortOrder = i;
        changedActivities.add(a);
      }
    }

    await SessionPlanActivityFunctions.updateSortOrdersAndBlockChanges(
        changedActivities);

    activities.sort((a, b) {
      final blockA = blockById[a.sessionPlanBlockId.id];
      final blockB = blockById[b.sessionPlanBlockId.id];
      final orderA = blockA?.sortOrder ?? 0;
      final orderB = blockB?.sortOrder ?? 0;
      return orderA != orderB
          ? orderA.compareTo(orderB)
          : a.sortOrder.compareTo(b.sortOrder);
    });

    notifyListeners();
  }

  Future<void> addBlock(String? name) async {
    final sortOrder = blocks.length;
    final newBlock = await SessionPlanBlockFunctions.create(
      courseId: _activeCourse!.id!,
      sessionPlanId: sessionPlan!.id!,
      name: name,
      sortOrder: sortOrder,
    );
    if (newBlock != null) {
      blocks.add(newBlock);
      blockById[newBlock.id!] = newBlock;
    }
    notifyListeners();
  }

  Future<void> deleteBlock(String blockId) async {
    await SessionPlanBlockFunctions.delete(blockId);
    blocks.removeWhere((b) => b.id == blockId);
    blockById.remove(blockId);

    final activitiesToRemove =
        activities.where((a) => a.sessionPlanBlockId.id == blockId).toList();
    for (final a in activitiesToRemove) {
      activityById.remove(a.id);
      activities.remove(a);
    }
    notifyListeners();
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
      courseId: _activeCourse!.id!,
      sessionPlanId: sessionPlan!.id!,
      sessionPlanBlockId: blockId,
      lessonId: lessonId,
      name: name,
      notes: notes,
      sortOrder: sortOrder,
      activityType: activityType,
    );
    if (newActivity != null) {
      activities.add(newActivity);
      activityById[newActivity.id!] = newActivity;
    }
    notifyListeners();
  }

  Future<void> deleteActivity(String activityId) async {
    await SessionPlanActivityFunctions.delete(activityId);
    activities.removeWhere((a) => a.id == activityId);
    activityById.remove(activityId);
    notifyListeners();
  }

  Future<void> updateActivity({
    required String activityId,
    String? lessonId,
    String? name,
    String? notes,
    int? overrideDuration,
  }) async {
    final updated = await SessionPlanActivityFunctions.update(
      activityId: activityId,
      lessonId: lessonId,
      name: name,
      notes: notes,
      overrideDuration: overrideDuration,
    );
    if (updated != null) {
      final index = activities.indexWhere((a) => a.id == activityId);
      if (index != -1) {
        activities[index] = updated;
      }
      activityById[activityId] = updated;
      notifyListeners();
    }
  }

  Future<void> updateActivityName(String activityId, String? name) async {
    await updateActivity(activityId: activityId, name: name);
  }

  Future<void> updateActivityNotes(String activityId, String? notes) async {
    await updateActivity(activityId: activityId, notes: notes);
  }

  Future<void> updateActivityOverrideDuration(
      {required String activityId, int? overrideDuration}) async {
    await updateActivity(
        activityId: activityId, overrideDuration: overrideDuration);
  }

  List<SessionPlanActivity> getActivitiesForBlock(String blockId) {
    return activities.where((a) => a.sessionPlanBlockId.id == blockId).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  int getTotalDurationMinutesForBlock(String blockId) {
    final blockActivities = getActivitiesForBlock(blockId);
    int totalMinutes = 0;
    for (final a in blockActivities) {
      totalMinutes += a.overrideDuration ??
          courseProfile?.defaultTeachableItemDurationInMinutes ??
          15;
    }
    return totalMinutes;
  }

  String getDurationStringForBlock(String blockId) {
    final mins = getTotalDurationMinutesForBlock(blockId);
    final hours = mins ~/ 60;
    final minutes = mins % 60;
    return hours == 0
        ? ':${minutes.toString().padLeft(2, '0')}'
        : '$hours:${minutes.toString().padLeft(2, '0')}';
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

  List<String> getUnscheduledObjectiveLessonIds() {
    final needed = <String>{};
    for (final objective in learningObjectives) {
      for (final tiRef in objective.teachableItemRefs) {
        final item = itemById[tiRef.id];
        if (item?.lessonRefs == null) continue;
        for (final lessonRef in item!.lessonRefs!) {
          needed.add(lessonRef.id);
        }
      }
    }
    for (final act in activities) {
      if (act.lessonId != null) needed.remove(act.lessonId!.id);
    }
    return needed.toList();
  }

  void saveCourseProfile(CourseProfile updatedProfile) async {
    courseProfile =
        await CourseProfileFunctions.saveCourseProfile(updatedProfile);
  }
}

enum CourseDesignerStateStatus {
  uninitialized,
  initializing,
  initialized,
  noCourseSelected,
  waitingOnAI,
}
