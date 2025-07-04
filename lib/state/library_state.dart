import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// import 'package:googleapis/docs/v1.dart';
import 'package:social_learning/data/Level.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:social_learning/data/lesson_comment.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:collection/collection.dart';
import 'package:social_learning/state/student_state.dart';

class LibraryState extends ChangeNotifier {
  final ApplicationState _applicationState;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _publicCourseListListener;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _levelListListener;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _lessonListListener;

  bool get isCourseSelected => _selectedCourse != null;

  Course? _selectedCourse;
  bool _isSelectedCourseInitializedFromDb = false;

  Course? get selectedCourse {
    if (_selectedCourse == null &&
        availableCourses.isNotEmpty &&
        !_isSelectedCourseInitializedFromDb) {
      var currentCourseId = _applicationState.currentUser?.currentCourseId;
      if (currentCourseId != null) {
        Course? foundCourse = availableCourses
            .firstWhereOrNull((course) => course.id == currentCourseId.id);

        if (foundCourse != null) {
          _isSelectedCourseInitializedFromDb = true;
          selectedCourse = foundCourse;
        }
      }
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
    User? currentUser = _applicationState.currentUser;
    if (courseId != null &&
        currentUser != null &&
        currentUser.currentCourseId?.id != courseId) {
      () async {
        FirebaseFirestore.instance.collection('users').doc(currentUser.id).set({
          'currentCourseId':
              FirebaseFirestore.instance.doc('/courses/$courseId')
        }, SetOptions(merge: true));
      }();
    }

    print('LibraryState.notifyListeners because of selectedCourse');
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
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

    if (_publicCourseListListener != null) {
      _publicCourseListListener?.cancel();
    }

    _publicCourseListListener = FirebaseFirestore.instance
        .collection('courses')
        .where('isPrivate', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      _publicCourses =
          snapshot.docs.map((e) => Course.fromSnapshot(e)).toList();
      _rebuildAvailableCourses();
      print('Loaded ${_publicCourses.length} public courses');
      notifyListeners();
    }, onError: (error, stackTrace) {
      print('Failed to load public courses: $error');
    });

    _reloadEnrolledCourses();
  }

  Future<void> _reloadEnrolledCourses() async {
    var enrolledCourseIds = _applicationState.currentUser?.enrolledCourseIds;

    if (enrolledCourseIds != null && enrolledCourseIds.isNotEmpty) {
      QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('courses')
          .where(FieldPath.documentId, whereIn: enrolledCourseIds)
          .where('isPrivate', isEqualTo: true)
          .get()
          .onError((Object error, StackTrace stackTrace) {
        print('Failed to load private courses: $error');
        return Future.error(error, stackTrace);
      });
      _enrolledPrivateCourses =
          snapshot.docs.map((e) => Course.fromSnapshot(e)).toList();
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
      if (_lessonListListener != null) {
        _lessonListListener?.cancel();
        _lessonListListener = null;
      }

      String coursePath = '/courses/$courseId';

      _lessonListListener = FirebaseFirestore.instance
          .collection('lessons')
          .where('courseId',
              isEqualTo: FirebaseFirestore.instance.doc(coursePath))
          .orderBy('sortOrder', descending: false)
          .snapshots()
          .listen((snapshot) {
        _lessons = snapshot.docs.map((e) => Lesson.fromSnapshot(e)).toList();
        print('Loaded ${_lessons?.length} lessons');
        notifyListeners();
      });
    }
  }

  Future<void> loadLevelList() async {
    var courseId = selectedCourse?.id;
    if (courseId != null) {
      if (_levelListListener != null) {
        _levelListListener?.cancel();
        _levelListListener = null;
      }

      String coursePath = '/courses/$courseId';

      _levelListListener = FirebaseFirestore.instance
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
      String courseId, String title, String instructions, bool isLevel) async {
    FirebaseFirestore.instance.collection('lessons').add(<String, dynamic>{
      'courseId': FirebaseFirestore.instance.doc('/courses/$courseId'),
      'sortOrder': _lessons?.length ?? 0,
      'title': title,
      'instructions': instructions,
      'creatorId': auth.FirebaseAuth.instance.currentUser!.uid,
      'isLevel': isLevel,
    });
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
      'creatorId': currentUser!.uid,
      'graduationRequirements': graduationRequirements,
    });

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
    _applicationState.enrollInPrivateCourse(course);

    return course;
  }

  Future<Course?> joinPrivateCourse(String invitationCode) async {
    var snapshot = await FirebaseFirestore.instance
        .collection('courses')
        .where('invitationCode', isEqualTo: invitationCode)
        .get();
    if (snapshot.docs.isNotEmpty) {
      var course = Course.fromSnapshot(snapshot.docs.first);

      // Enroll in the private course.
      await _applicationState.enrollInPrivateCourse(course);

      // Load the enrolled course into LibraryState.
      await _reloadEnrolledCourses();

      // Select the private course.
      selectedCourse = _availableCourses
          .firstWhereOrNull((element) => element.id == course.id);

      return course;
    } else {
      // Course not found.
      return Future.value(null);
    }
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

  addLessonComment(Lesson lesson, String comment) async {
    User user = _applicationState.currentUser!;
    DocumentReference userId =
        FirebaseFirestore.instance.doc('/users/${user.id}');
    DocumentReference lessonId =
        FirebaseFirestore.instance.doc('/lessons/${lesson.id}');

    await FirebaseFirestore.instance.collection('lessonComments').add({
      'lessonId': lessonId,
      'text': comment,
      'creatorId': userId,
      'creatorUid': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    print('finished firebase call to create comment');
  }

  deleteLessonComment(LessonComment comment) async {
    print('Deleting comment: ${comment.id}');
    await FirebaseFirestore.instance
        .doc('/lessonComments/${comment.id}')
        .delete()
        .onError((error, stackTrace) {
      print('Failed to delete comment: $error');
      debugPrintStack(stackTrace: stackTrace);
    });
  }

  Future<bool> doesCourseTitleExist(String title) async {
    return await FirebaseFirestore.instance
        .collection('courses')
        .where('title', isEqualTo: title)
        .get()
        .then((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return true;
      } else {
        return false;
      }
    });
  }

  Future<bool> doesInvitationCodeExist(String title) async {
    return await FirebaseFirestore.instance
        .collection('courses')
        .where('invitationCode', isEqualTo: title)
        .get()
        .then((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return true;
      } else {
        return false;
      }
    });
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
    _isSelectedCourseInitializedFromDb = false;
    _selectedCourse = null;
    _enrolledPrivateCourses = [];
    _isCourseListLoaded = false;
    _isLevelListLoaded = false;
    _isLessonListLoaded = false;
  }
}
