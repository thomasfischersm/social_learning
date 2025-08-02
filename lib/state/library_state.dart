import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:social_learning/data/Level.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/lesson_comment.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:collection/collection.dart';
import 'package:social_learning/state/student_state.dart';
import 'package:social_learning/data/data_helpers/course_functions.dart';
import 'package:social_learning/data/data_helpers/lesson_functions.dart';
import 'package:social_learning/data/data_helpers/level_functions.dart';
import 'package:social_learning/data/data_helpers/lesson_comment_functions.dart';
import 'package:social_learning/data/data_helpers/user_functions.dart';

class LibraryState extends ChangeNotifier {
  final ApplicationState _applicationState;

  StreamSubscription<List<Course>>? _publicCourseListListener;

  StreamSubscription<List<Level>>? _levelListListener;

  StreamSubscription<List<Lesson>>? _lessonListListener;

  bool get isCourseSelected => _selectedCourse != null;

  Course? _selectedCourse;
  bool _isInitialized = false;
  late Completer<void> _initializationCompleter;

  Course? get selectedCourse => _selectedCourse;

  set selectedCourse(Course? course) {
    if (_selectedCourse != course) {
      _lessonListListener?.cancel();
      _levelListListener?.cancel();
      _lessons = null;
      _levels = null;

      _selectedCourse = course;

      if (course?.id != null) {
        _loadSelectedCourseData(course!.id!);
      }

      String? courseId = course?.id;
      User? currentUser = _applicationState.currentUser;
      if (courseId != null &&
          currentUser != null &&
          currentUser.currentCourseId?.id != courseId) {
        UserFunctions.updateCurrentCourse(currentUser, courseId);
      }

      print('LibraryState.notifyListeners because of selectedCourse');
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  var _availableCourses = <Course>[];
  var _publicCourses = <Course>[];
  var _enrolledPrivateCourses = <Course>[];

  List<Course> get availableCourses => _availableCourses;

  List<Lesson>? _lessons;
  List<Lesson>? get lessons => _lessons;

  List<Level>? _levels;
  List<Level>? get levels => _levels;

  LibraryState(this._applicationState) {
    _initializationCompleter = Completer<void>();
    _applicationState.addListener(() {
      _reloadEnrolledCourses();
      final currentCourseId =
          _applicationState.currentUser?.currentCourseId?.id;
      if (currentCourseId != null &&
          (_selectedCourse == null || _selectedCourse!.id != currentCourseId)) {
        final Course? found =
            _availableCourses.firstWhereOrNull((c) => c.id == currentCourseId);
        if (found != null) {
          selectedCourse = found;
        }
      }
    });
  }

  Future<void> initialize() async {
    if (_isInitialized) {
      return _initializationCompleter.future;
    }
    _isInitialized = true;

    final currentCourseId =
        _applicationState.currentUser?.currentCourseId?.id;

    final futures = <Future<void>>[loadCourseList()];
    if (currentCourseId != null) {
      futures.add(_loadSelectedCourseData(currentCourseId));
    }

    await Future.wait(futures);

    if (currentCourseId != null) {
      final Course? course =
          _availableCourses.firstWhereOrNull((c) => c.id == currentCourseId);
      if (course != null) {
        _selectedCourse = course;
      }
    }

    _initializationCompleter.complete();
    return _initializationCompleter.future;
  }

  Future<void> get initialized => _initializationCompleter.future;

  Future<void> loadCourseList() async {
    _publicCourseListListener?.cancel();
    final publicCompleter = Completer<void>();

    _publicCourseListListener = CourseFunctions.listenPublicCourses((courses) {
      _publicCourses = courses;
      _rebuildAvailableCourses();
      if (!publicCompleter.isCompleted) {
        publicCompleter.complete();
      }
      print('Loaded ${_publicCourses.length} public courses');
      notifyListeners();
    }, onError: (error, stackTrace) {
      print('Failed to load public courses: $error');
    });

    await Future.wait([publicCompleter.future, _reloadEnrolledCourses()]);
  }

  Future<void> _reloadEnrolledCourses() async {
    var enrolledCourseIds = _applicationState.currentUser?.enrolledCourseIds;

    if (enrolledCourseIds != null && enrolledCourseIds.isNotEmpty) {
      _enrolledPrivateCourses =
          await CourseFunctions.fetchEnrolledPrivateCourses(enrolledCourseIds);
      _rebuildAvailableCourses();
      print('Loaded ${_enrolledPrivateCourses.length} enrolled courses');
      notifyListeners();
    } else {
      if (_enrolledPrivateCourses.isNotEmpty) {
        _enrolledPrivateCourses = [];
        _rebuildAvailableCourses();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          print(
              'LibraryState.notifyListeners because of reload private courses.');
          notifyListeners();
        });
      }
    }
  }

  _rebuildAvailableCourses() {
    _availableCourses = HashSet<Course>.from(_publicCourses)
        .union(HashSet<Course>.from(_enrolledPrivateCourses))
        .toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  }

  Future<void> _loadSelectedCourseData(String courseId) {
    return Future.wait([loadLessonList(courseId), loadLevelList(courseId)]);
  }

  Future<void> loadLessonList([String? courseId]) async {
    courseId = courseId ?? _selectedCourse?.id;
    if (courseId != null) {
      _lessonListListener?.cancel();
      final completer = Completer<void>();

      _lessonListListener =
          LessonFunctions.listenLessons(courseId, (lessonList) {
        _lessons = lessonList;
        if (!completer.isCompleted) {
          completer.complete();
        }
        print('Loaded ${_lessons?.length} lessons');
        notifyListeners();
      });

      await completer.future;
    }
  }

  Future<void> loadLevelList([String? courseId]) async {
    courseId = courseId ?? _selectedCourse?.id;
    if (courseId != null) {
      _levelListListener?.cancel();
      final completer = Completer<void>();

      _levelListListener =
          LevelFunctions.listenLevels(courseId, (levelList) {
        _levels = levelList;
        if (!completer.isCompleted) {
          completer.complete();
        }
        print('Loaded ${_levels?.length} levels');
        notifyListeners();
      });

      await completer.future;
    }
  }

  Iterable<Lesson> getLessonsByLevel(String rawLevelId) {
    var lessonsRef = lessons;
    if (lessonsRef != null) {
      return lessonsRef.where((element) {
        var otherLevelId = element.levelId;
        if (otherLevelId != null) {
          return otherLevelId.id == rawLevelId;
        } else {
          return false;
        }
      });
    } else {
      return [];
    }
  }

  Iterable<Lesson> getUnattachedLessons() {
    var lessonsRef = lessons;
    if (lessonsRef != null) {
      var unsortedLessons =
          lessonsRef.where((element) => element.levelId == null);
      unsortedLessons.sortedBy<num>((element) => element.sortOrder);
      return unsortedLessons;
    } else {
      return [];
    }
  }

  Lesson? findLesson(String? lessonId) {
    if (lessonId == null) {
      return null;
    }

    return lessons?.firstWhereOrNull((lesson) => lesson.id == lessonId);
  }

  Lesson? findPreviousLesson(Lesson? currentLesson) {
    List<Lesson>? lessons = _lessons;
    if (lessons != null && currentLesson != null) {
      var currentIndex = lessons.indexOf(currentLesson) - 1;
      while (currentIndex >= 0 && lessons[currentIndex].isLevel == true) {
        currentIndex--;
      }
      if (currentIndex > 0) {
        return lessons[currentIndex];
      }
    }
    return null;
  }

  Lesson? findNextLesson(Lesson? currentLesson) {
    List<Lesson>? lessons = _lessons;
    if (lessons != null && currentLesson != null) {
      var currentIndex = lessons.indexOf(currentLesson) + 1;
      while (currentIndex < lessons.length &&
          lessons[currentIndex].isLevel == true) {
        currentIndex++;
      }
      if (currentIndex < lessons.length) {
        return lessons[currentIndex];
      }
    }
    return null;
  }

  void updateSortOrder(Lesson touchedLesson, int newSortOrder) async {
    int oldSortOrder = touchedLesson.sortOrder;
    var lessons = _lessons;

    if (lessons == null) {
      return;
    }

    newSortOrder = max(newSortOrder, 0);
    newSortOrder = min(newSortOrder, lessons.length - 1);

    if ((newSortOrder == oldSortOrder)) {
      return;
    } else if (newSortOrder > oldSortOrder) {
      for (Lesson lesson in lessons) {
        if ((touchedLesson != lesson) &&
            (lesson.sortOrder > oldSortOrder) &&
            (lesson.sortOrder <= newSortOrder)) {
          _setSortOrder(lesson, lesson.sortOrder - 1);
        }
      }
    } else {
      for (Lesson lesson in lessons) {
        if ((touchedLesson != lesson) &&
            (lesson.sortOrder < oldSortOrder) &&
            (lesson.sortOrder >= newSortOrder)) {
          _setSortOrder(lesson, lesson.sortOrder + 1);
        }
      }
    }

    _setSortOrder(touchedLesson, newSortOrder);
  }

  void _setSortOrder(Lesson lesson, int newSortOrder) async {
    print(
        '### Set sort order for ${lesson.title} from ${lesson.sortOrder} to $newSortOrder');
    try {
      await LessonFunctions.setSortOrder(lesson.id!, newSortOrder);
    } catch (e, stackTrace) {
      print('Failed to set sort order: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _setLevelSortOrder(Level level, int newSortOrder) async {
    await LevelFunctions.setSortOrder(level.id!, newSortOrder);
  }

  void deleteLesson(Lesson deletedLesson) {
    int sortOrder = deletedLesson.sortOrder;
    var lessons = _lessons;
    if (lessons == null) {
      return;
    }

    // Delete lesson.
    LessonFunctions.deleteLesson(deletedLesson.id!);

    // Update sortOrder for following lessons.
    for (Lesson lesson in lessons) {
      if ((deletedLesson != lesson) && (lesson.sortOrder > sortOrder)) {
        _setSortOrder(lesson, lesson.sortOrder - 1);
      }
    }

    // Delete cover photo.
    LessonFunctions.deleteCoverPhoto(deletedLesson.id!);
  }

  @Deprecated('Left over from the first version of the CMS.')
  void createLessonLegacy(
      String courseId, String title, String instructions, bool isLevel) async {
    await LessonFunctions.createLessonLegacy(courseId, title, instructions, isLevel);
  }

  Future<Lesson> createLesson(
      DocumentReference? levelId,
      String title,
      String? synopsis,
      String instructions,
      // String? cover,
      String? recapVideo,
      String? lessonVideo,
      String? practiceVideo,
      List<String>? graduationRequirements,
      StudentState studentState) async {
    var currentUser = _applicationState.currentUser;

    DocumentReference<Map<String, dynamic>> newLessonRef =
        await LessonFunctions.createLesson(
            courseId: selectedCourse!.id!,
            levelId: levelId,
            sortOrder: _findHighestLessonSortOrder() + 1,
            title: title,
            synopsis: synopsis,
            instructions: instructions,
            recapVideo: recapVideo,
            lessonVideo: lessonVideo,
            practiceVideo: practiceVideo,
            graduationRequirements: graduationRequirements,
            creatorId: currentUser!.uid);

    if (levelId == null) {
      sortUnattachedLessons();
    }

    // If it's a private course, create a practiceRecords entry so that the
    // creator can teach it.
    if (selectedCourse?.isPrivate == true) {
      studentState.recordTeaching(
          newLessonRef.id, selectedCourse!.id!, currentUser, true);
    }

    return Lesson.fromSnapshot(await newLessonRef.get());
  }

  @Deprecated('Left over from the first version of the CMS.')
  void updateLessonLegacy(
      String lessonId, String title, String instructions, bool isLevel) {
    LessonFunctions.updateLessonLegacy(lessonId, title, instructions, isLevel);
  }

  Future<void> updateLesson(Lesson lesson) async {
    // Clean up graduation requirements.
    if (lesson.graduationRequirements != null) {
      lesson.graduationRequirements!.removeWhere((element) => element.isEmpty);
    }

    await LessonFunctions.updateLesson(lesson.id!, {
      'levelId': lesson.levelId,
      'sortOrder': lesson.sortOrder,
      'title': lesson.title,
      'synopsis': lesson.synopsis,
      'instructions': lesson.instructions,
      'cover': lesson.cover,
      'coverFireStoragePath': lesson.coverFireStoragePath,
      'recapVideo': lesson.recapVideo,
      'lessonVideo': lesson.lessonVideo,
      'practiceVideo': lesson.practiceVideo,
      'graduationRequirements': lesson.graduationRequirements,
    });
  }

  void updateLevel(Level level) async {
    await LevelFunctions.updateLevel(level.id!, {
      'title': level.title,
      'description': level.description,
      'sortOrder': level.sortOrder,
    });
  }

  Level? findLevel(String levelId) =>
      levels?.firstWhereOrNull((element) => element.id == levelId);

  Level? findLevelByDocRef(DocumentReference levelRef) =>
      findLevel(levelRef.id);

  int findLevelPosition(Level? level) =>
      (level != null) ? levels?.indexOf(level) ?? -1 : -1;

  Future<Course> createPrivateCourse(
      String courseName,
      String invitationCode,
      String description,
      ApplicationState applicationState,
      LibraryState libraryState) async {
    DocumentReference<Map<String, dynamic>> docRef =
        await CourseFunctions.createPrivateCourse(
            title: courseName,
            description: description,
            invitationCode: invitationCode,
            creatorId: _applicationState.currentUser!.uid);
    var course = Course.fromDocument(await docRef.get());

    // Automatically enroll the creator in their own course.
    _applicationState.enrollInPrivateCourse(course);

    return course;
  }

  Future<Course?> joinPrivateCourse(String invitationCode) async {
    final course =
        await CourseFunctions.findCourseByInvitationCode(invitationCode);
    if (course != null) {
      await _applicationState.enrollInPrivateCourse(course);
      await _reloadEnrolledCourses();
      selectedCourse =
          _availableCourses.firstWhereOrNull((element) => element.id == course.id);
    }
    return course;
  }

  void deleteLevel(Level level) {
    int sortOrder = level.sortOrder;
    var levels = _levels;
    if (levels == null) {
      return;
    }

    // Detach lessons first.
    for (Lesson lesson in getLessonsByLevel(level.id!)) {
      detachLesson(lesson);
    }

    // Delete level.
    LevelFunctions.deleteLevel(level.id!);

    // Update sortOrder for following levels.
    for (Level otherLevel in levels) {
      if ((level != otherLevel) && (otherLevel.sortOrder > sortOrder)) {
        _setLevelSortOrder(otherLevel, otherLevel.sortOrder - 1);
      }
    }
  }

  void addLevel(String title, String description) async {
    var sortOrder = _findHighestLevelSortOrder();

    await LevelFunctions.addLevel(
        courseId: selectedCourse!.id!,
        title: title,
        description: description,
        sortOrder: sortOrder + 1,
        creatorId: _applicationState.currentUser!.uid);
  }

  _findHighestLevelSortOrder() {
    var localLevels = levels;
    if ((localLevels == null) || localLevels.isEmpty) {
      return 0;
    }

    int maxSortOrder = localLevels.first.sortOrder;
    for (final level in localLevels.skip(1)) {
      maxSortOrder = max(maxSortOrder, level.sortOrder);
    }
    return maxSortOrder;
  }

  _findHighestLessonSortOrder() {
    var localLessons = lessons;
    if ((localLessons == null) || localLessons.isEmpty) {
      return 0;
    }

    int maxSortOrder = localLessons.first.sortOrder;
    for (final lesson in localLessons.skip(1)) {
      maxSortOrder = max(maxSortOrder, lesson.sortOrder);
    }
    return maxSortOrder;
  }

  void detachLesson(Lesson lesson) async {
    // Remove the level.
    await LessonFunctions.detachLesson(lesson.id!);

    // Sort the unattached lessons.
    var unattachedLessons = getUnattachedLessons().toList();
    unattachedLessons
        .sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    // Find the right spot in the alphabetically sorted unattached lessons.
    // Or if there are no unattached lessons, find the highest sort order.
    int? followingLessonSortOrder = unattachedLessons
        .firstWhereOrNull((otherLesson) =>
            otherLesson.title
                .toLowerCase()
                .compareTo(lesson.title.toLowerCase()) >
            0)
        ?.sortOrder;
    int newSortOrder = (followingLessonSortOrder != null)
        ? followingLessonSortOrder - 1
        : _findHighestLessonSortOrder();

    updateSortOrder(lesson, newSortOrder);

    // sortUnattachedLessons();
  }

  void attachLesson(Level level, Lesson selectedLesson, int sortOrder) async {
    await LessonFunctions.attachLessonToLevel(selectedLesson.id!, level.id!);

    updateSortOrder(selectedLesson, sortOrder);

    // TODO: Remove
    _fixSortOrderForDebugging();
  }

  /// Returns the sort order for a specified level, which doesn't have any
  /// lessons yet. The trick is that the lesson in a previous level has to be
  /// found.
  int findSortLessonOrderForEmptyLevel(Level level) {
    int? levelIndex = levels?.indexOf(level);
    if (levelIndex == null) {
      return 0;
    }

    while ((levelIndex != null) && (levelIndex > 0)) {
      levelIndex--;
      Level previousLevel = levels![levelIndex];
      var lessons = getLessonsByLevel(previousLevel.id!);
      if (lessons.isNotEmpty) {
        return lessons.last.sortOrder + 1;
      }
    }

    // No lesson found in any previous level.
    return 0;
  }

  sortUnattachedLessons() {
    // Get the highest sort order of attached lessons.
    var attachedLessons = lessons?.where((lesson) => lesson.levelId != null);
    int highestSortOrder =
        attachedLessons?.fold(0, (int? previousValue, lesson) {
              return max(previousValue!, lesson.sortOrder);
            }) ??
            0;

    // Sort the unattached lessons.
    var unattachedLessons = getUnattachedLessons().toList();
    unattachedLessons
        .sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    // Update the sort order if necessary.
    for (int i = 0; i < unattachedLessons.length; i++) {
      var newSortOrder = i + highestSortOrder + 1;
      if (unattachedLessons[i].sortOrder != newSortOrder) {
        _setSortOrder(unattachedLessons[i], newSortOrder);
      }
    }
  }

  _fixSortOrderForDebugging() {
    int sortOrder = 0;
    for (Level level in levels!) {
      for (Lesson lesson in getLessonsByLevel(level.id!)) {
        if (lesson.sortOrder != sortOrder) {
          print(
              '!!! Fixing sort order for ${lesson.title} from ${lesson.sortOrder} to $sortOrder');
          _setSortOrder(lesson, sortOrder);
        }
        sortOrder++;
      }
    }

    var unattachedLessons = getUnattachedLessons().toList();
    unattachedLessons
        .sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    for (Lesson lesson in unattachedLessons) {
      if (lesson.sortOrder != sortOrder) {
        print(
            '!!! Fixing sort order for ${lesson.title} from ${lesson.sortOrder} to $sortOrder');
        _setSortOrder(lesson, sortOrder);
      }
      sortOrder++;
    }
  }

  addLessonComment(Lesson lesson, String comment) async {
    User user = _applicationState.currentUser!;
    await LessonCommentFunctions.addComment(
        lessonId: lesson.id!,
        userId: user.id,
        creatorUid: user.uid,
        text: comment);
  }

  deleteLessonComment(LessonComment comment) async {
    print('Deleting comment: ${comment.id}');
    try {
      await LessonCommentFunctions.deleteComment(comment.id!);
    } catch (error, stackTrace) {
      print('Failed to delete comment: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }


  Future<bool> doesCourseTitleExist(String title) async {
    return CourseFunctions.titleExists(title);
  }

  Future<bool> doesInvitationCodeExist(String title) async {
    return CourseFunctions.invitationCodeExists(title);
  }

  void signOut() {
    // Cancel subscriptions.
    _publicCourseListListener?.cancel();
    _publicCourseListListener = null;

    _lessonListListener?.cancel();
    _lessonListListener = null;

    _levelListListener?.cancel();
    _levelListListener = null;

    _selectedCourse = null;
    _availableCourses = [];
    _publicCourses = [];
    _enrolledPrivateCourses = [];
    _lessons = null;
    _levels = null;
    _isInitialized = false;
    _initializationCompleter = Completer<void>();
  }
}
