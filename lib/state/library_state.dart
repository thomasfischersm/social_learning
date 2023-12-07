import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_learning/data/Level.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class LibraryState extends ChangeNotifier {
  bool get isCourseSelected => _selectedCourse != null;

  Course? _selectedCourse;

  Course? get selectedCourse {
    if (_selectedCourse == null && _availableCourses.isNotEmpty) {
      () async {
        var prefs = await SharedPreferences.getInstance();
        var tmp = prefs.getString('selectedCourseId');
        if (tmp != null && tmp.isNotEmpty) {
          selectedCourse =
              _availableCourses.firstWhere((element) => element.id == tmp);
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

  Future<void> loadCourseList() async {
    // Create courses.
    // FirebaseFirestore.instance.collection('courses').add(<String, dynamic>{
    //   'title': 'Argentine Tango',
    //   'creatorId': auth.FirebaseAuth.instance.currentUser!.uid,
    // });

    FirebaseFirestore.instance
        .collection('courses')
        .orderBy('title', descending: false)
        .snapshots()
        .listen((snapshot) {
      _availableCourses =
          snapshot.docs.map((e) => Course.fromSnapshot(e)).toList();
      print('Loaded ${_availableCourses.length} courses');
      notifyListeners();
    });
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

  Lesson? findLesson(String lessonId) {
    return _lessons?.firstWhere((lesson) => lesson.id == lessonId);
  }

  Lesson? findPreviousLesson(Lesson? currentLesson) {
    List<Lesson>? lessons = _lessons;
    if (lessons != null && currentLesson != null) {
      var currentIndex = lessons.indexOf(currentLesson) - 1;
      while (currentIndex >= 0 && lessons[currentIndex].isLevel) {
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
      while (currentIndex < lessons.length && lessons[currentIndex].isLevel) {
        currentIndex++;
      }
      if (currentIndex < lessons.length) {
        return lessons[currentIndex];
      }
    }
    return null;
  }

  void updateSortOrder(Lesson touchedLesson, int newSortOrder) {
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

  void _setSortOrder(Lesson lesson, int newSortOrder) {
    FirebaseFirestore.instance.doc('/lessons/${lesson.id}').set({
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
  }

  void createLesson(
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

  void updateLesson(
      String lessonId, String title, String instructions, bool isLevel) {
    FirebaseFirestore.instance.doc('/lessons/$lessonId').set({
      'title': title,
      'instructions': instructions,
      'creatorId': auth.FirebaseAuth.instance.currentUser!.uid,
      'isLevel': isLevel,
    }, SetOptions(merge: true));
  }

  Level? findLevel(String levelId) =>
      levels?.firstWhere((element) => element.id == levelId);

  Level? findLevelByDocRef(DocumentReference levelRef) =>
      findLevel(levelRef.id);

  int findLevelPosition(Level? level) =>
      (level != null) ? levels?.indexOf(level) ?? -1 : -1;
}
