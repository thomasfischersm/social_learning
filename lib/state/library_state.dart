import 'dart:collection';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_learning/data/Level.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:social_learning/state/application_state.dart';
import 'package:collection/collection.dart';

class LibraryState extends ChangeNotifier {
  ApplicationState _applicationState;

  bool get isCourseSelected => _selectedCourse != null;

  Course? _selectedCourse;
  bool _isSelectedCourseInitializedFromPrefs = false;

  Course? get selectedCourse {
    if (_selectedCourse == null &&
        _availableCourses.isNotEmpty &&
        !_isSelectedCourseInitializedFromPrefs) {
      () async {
        var prefs = await SharedPreferences.getInstance();
        var tmp = prefs.getString('selectedCourseId');
        if (tmp != null && tmp.isNotEmpty && _availableCourses.isNotEmpty) {
          selectedCourse = _availableCourses
              .firstWhereOrNull((element) => element.id == tmp);
          _isSelectedCourseInitializedFromPrefs = true;
        }
      }();
    }

    return _selectedCourse;
  }

  set selectedCourse(Course? course) {
    if (_selectedCourse != course) {
      _lessons = null;
      _isLessonListLoaded = false;
      _isLevelListLoaded = false;
    }

    _selectedCourse = course;

    String? courseId = course?.id;
    if (courseId != null) {
      () async {
        var prefs = await SharedPreferences.getInstance();
        prefs.setString('selectedCourseId', courseId);
      }();
    }

    notifyListeners();
  }

  var _availableCourses = <Course>[];
  var _publicCourses = <Course>[];
  var _enrolledPrivateCourses = <Course>[];
  bool _isCourseListLoaded = false;

  List<Course> get availableCourses {
    if (!_isCourseListLoaded) {
      _isCourseListLoaded = true;
      loadCourseList();
    }
    return _availableCourses;
  }

  List<Lesson>? _lessons;
  bool _isLessonListLoaded = false;

  List<Lesson>? get lessons {
    if (!_isLessonListLoaded) {
      _isLessonListLoaded = true;
      loadLessonList();
    }
    return _lessons;
  }

  List<Level>? _levels;
  bool _isLevelListLoaded = false;

  List<Level>? get levels {
    if (!_isLevelListLoaded) {
      _isLevelListLoaded = true;
      loadLevelList();
    }
    return _levels;
  }

  LibraryState(this._applicationState) {
    _applicationState.addListener(() {
      _reloadEnrolledCourses();
    });
  }

  Future<void> loadCourseList() async {
    // Create courses.
    // FirebaseFirestore.instance.collection('courses').add(<String, dynamic>{
    //   'title': 'Argentine Tango',
    //   'creatorId': auth.FirebaseAuth.instance.currentUser!.uid,
    // });

    FirebaseFirestore.instance
        .collection('courses')
        .where('isPrivate', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      _publicCourses =
          snapshot.docs.map((e) => Course.fromSnapshot(e)).toList();
      _rebuildAvailableCourses();
      print('Loaded ${_publicCourses.length} public courses');
      notifyListeners();
    }).onError((error, stackTrace) {
      print('Failed to load public courses: $error');
    });

    _reloadEnrolledCourses();
  }

  void _reloadEnrolledCourses() async {
    var enrolledCourseIds = _applicationState.currentUser?.enrolledCourseIds;

    if (enrolledCourseIds == null) {
      FirebaseFirestore.instance
          .collection('courses')
          .where(FieldPath.documentId, whereIn: enrolledCourseIds)
          .where('isPrivate', isEqualTo: true)
          .get()
          .then((snapshot) {
        _enrolledPrivateCourses =
            snapshot.docs.map((e) => Course.fromSnapshot(e)).toList();
        _rebuildAvailableCourses();
        print('Loaded ${_enrolledPrivateCourses.length} enrolled courses');
        notifyListeners();
      }).onError((error, stackTrace) {
        print('Failed to load enrolled courses: $error');
      });
    } else {
      if (_enrolledPrivateCourses.isNotEmpty) {
        _enrolledPrivateCourses = [];
        _rebuildAvailableCourses();

        WidgetsBinding.instance.addPostFrameCallback((_) {
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

  Future<void> loadLessonList() async {
    // Create courses.
    // FirebaseFirestore.instance.collection('lessons').add(<String, dynamic>{
    //   'courseId': FirebaseFirestore.instance.doc('/courses/4ZUgIakaAbcCiVWMxSKb'),
    //   'sortOrder': 1,
    //   'title': 'Wohoo!',
    //   'instructions': 'Couple work: Basic and inside turn',
    //   'creatorId': auth.FirebaseAuth.instance.currentUser!.uid,
    //   'isLevel': false,
    // });
    // FirebaseFirestore.instance.collection('lessons').add(<String, dynamic>{
    //   'courseId': FirebaseFirestore.instance.doc('/courses/4ZUgIakaAbcCiVWMxSKb'),
    //   'sortOrder': 2,
    //   'title': 'First dance',
    //   'instructions': 'Couple work: Basic and inside turn',
    //   'creatorId': auth.FirebaseAuth.instance.currentUser!.uid,
    //   'isLevel': false,
    // });

    var courseId = selectedCourse?.id;
    if (courseId != null) {
      String coursePath = '/courses/$courseId';

      FirebaseFirestore.instance
          .collection('lessons')
          .where('courseId',
              isEqualTo: FirebaseFirestore.instance.doc(coursePath))
          .orderBy('sortOrder', descending: false)
          .snapshots()
          .listen((snapshot) {
        _lessons = snapshot.docs.map((e) => Lesson.fromSnapshot(e)).toList();
        notifyListeners();
      });
    }
  }

  Future<void> loadLevelList() async {
    var courseId = selectedCourse?.id;
    if (courseId != null) {
      String coursePath = '/courses/$courseId';

      FirebaseFirestore.instance
          .collection('levels')
          .where('courseId',
              isEqualTo: FirebaseFirestore.instance.doc(coursePath))
          .orderBy('sortOrder', descending: false)
          .snapshots()
          .listen((snapshot) {
        _levels = snapshot.docs.map((e) => Level.fromQuerySnapshot(e)).toList();
        print('Loaded ${_levels?.length} levels');
        notifyListeners();
      });
      // TODO: Cancel this subscription and other subscriptions.
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

  Lesson? findLesson(String lessonId) {
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
    await FirebaseFirestore.instance.doc('/lessons/${lesson.id}').set({
      'sortOrder': newSortOrder,
      'creatorId': auth.FirebaseAuth.instance.currentUser!.uid
    }, SetOptions(merge: true)).onError((error, stackTrace) {
      print('Failed to set sort order: $error');
      debugPrintStack(stackTrace: stackTrace);
    });
  }

  void _setLevelSortOrder(Level level, int newSortOrder) async {
    await FirebaseFirestore.instance.doc('/levels/${level.id}').set({
      'sortOrder': newSortOrder,
      'creatorId': auth.FirebaseAuth.instance.currentUser!.uid
    }, SetOptions(merge: true));
  }

  void deleteLesson(Lesson deletedLesson) {
    int sortOrder = deletedLesson.sortOrder;
    var lessons = _lessons;
    if (lessons == null) {
      return;
    }

    // Delete lesson.
    FirebaseFirestore.instance.doc('/lessons/${deletedLesson.id}').delete();

    // Update sortOrder for following lessons.
    for (Lesson lesson in lessons) {
      if ((deletedLesson != lesson) && (lesson.sortOrder > sortOrder)) {
        _setSortOrder(lesson, lesson.sortOrder - 1);
      }
    }

    // TODO: Delete cover photo.
    _deleteCoverPhoto(deletedLesson);
  }

  void _deleteCoverPhoto(Lesson lesson) async {
    var fireStoragePath = '/lesson_covers/${lesson.id}/coverPhoto';
    var storageRef = FirebaseStorage.instance.ref(fireStoragePath);
    try {
      // var imageData = await file.readAsBytes();
      await storageRef.delete();
    } catch (e) {
      print('Error deleting photo: $e');
    }
  }

  @Deprecated('Left over from the first version of the CMS.')
  void createLessonLegacy(
      String courseId, String title, String instructions, bool isLevel) {
    FirebaseFirestore.instance.collection('lessons').add(<String, dynamic>{
      'courseId': FirebaseFirestore.instance.doc('/courses/$courseId'),
      'sortOrder': _lessons?.length ?? 0,
      'title': title,
      'instructions': instructions,
      'creatorId': auth.FirebaseAuth.instance.currentUser!.uid,
      'isLevel': isLevel,
    });
  }

  Future<void> createLesson(
      DocumentReference? levelId,
      String title,
      String? synopsis,
      String instructions,
      // String? cover,
      String? recapVideo,
      String? lessonVideo,
      String? practiceVideo,
      List<String>? graduationRequirements) async {
    await FirebaseFirestore.instance
        .collection('lessons')
        .add(<String, dynamic>{
      'courseId':
          FirebaseFirestore.instance.doc('/courses/${selectedCourse?.id}'),
      'levelId': levelId,
      'sortOrder': _findHighestLessonSortOrder() + 1,
      // TODO: If levelId is null, use the highest sort order of the level.
      'title': title,
      'synopsis': synopsis,
      'instructions': instructions,
      // 'cover': cover, // TODO: Implement image upload.
      // 'coverFireStoragePath': coverFireStoragePath,
      'recapVideo': recapVideo,
      'lessonVideo': lessonVideo,
      'practiceVideo': practiceVideo,
      'creatorId': auth.FirebaseAuth.instance.currentUser!.uid,
      'graduationRequirements': graduationRequirements,
    });

    if (levelId == null) {
      sortUnattachedLessons();
    }
  }

  @Deprecated('Left over from the first version of the CMS.')
  void updateLessonLegacy(
      String lessonId, String title, String instructions, bool isLevel) {
    FirebaseFirestore.instance.doc('/lessons/$lessonId').set({
      'title': title,
      'instructions': instructions,
      'creatorId': auth.FirebaseAuth.instance.currentUser!.uid,
      'isLevel': isLevel,
    }, SetOptions(merge: true));
  }

  Future<void> updateLesson(Lesson lesson) async {
    // Clean up graduation requirements.
    if (lesson.graduationRequirements != null) {
      lesson.graduationRequirements!.removeWhere((element) => element.isEmpty);
    }

    await FirebaseFirestore.instance.doc('/lessons/${lesson.id}').set({
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
    }, SetOptions(merge: true));
  }

  void updateLevel(Level level) async {
    await FirebaseFirestore.instance.doc('levels/${level.id}').set({
      'title': level.title,
      'description': level.description,
      'sortOrder': level.sortOrder,
    }, SetOptions(merge: true));
  }

  Level? findLevel(String levelId) =>
      levels?.firstWhere((element) => element.id == levelId);

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
    DocumentReference<Map<String, dynamic>> docRef = await FirebaseFirestore
        .instance
        .collection('/courses')
        .add(<String, dynamic>{
      'title': courseName,
      'description': description,
      'creatorId': auth.FirebaseAuth.instance.currentUser!.uid,
      'isPrivate': true,
      'invitationCode': invitationCode
    });
    var doc = await docRef.get();
    var course = Course.fromDocument(doc);

    // Automatically enroll the creator in their own course.
    _applicationState.enrollInPrivateCourse(course, applicationState);

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
    FirebaseFirestore.instance.doc('/levels/${level.id}').delete();

    // Update sortOrder for following levels.
    for (Level otherLevel in levels) {
      if ((level != otherLevel) && (otherLevel.sortOrder > sortOrder)) {
        _setLevelSortOrder(otherLevel, otherLevel.sortOrder - 1);
      }
    }
  }

  void addLevel(String title, String description) async {
    var sortOrder = _findHighestLevelSortOrder();

    await FirebaseFirestore.instance.collection('/levels').add({
      'courseId':
          FirebaseFirestore.instance.doc('/courses/${selectedCourse?.id}'),
      'title': title,
      'description': description,
      'sortOrder': sortOrder + 1,
      'creatorId': auth.FirebaseAuth.instance.currentUser!.uid,
    });
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
    await FirebaseFirestore.instance.doc('/lessons/${lesson.id}').set({
      'levelId': null,
    }, SetOptions(merge: true));

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
    await FirebaseFirestore.instance.doc('/lessons/${selectedLesson.id}').set({
      'levelId': FirebaseFirestore.instance.doc('/levels/${level.id}'),
    }, SetOptions(merge: true));

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
}
