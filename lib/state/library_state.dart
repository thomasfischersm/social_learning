import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/lesson.dart';

class LibraryState extends ChangeNotifier {
  bool get isCourseSelected => _selectedCourse != null;

  Course? _selectedCourse;

  Course? get selectedCourse {
    if (_selectedCourse == null && _availableCourses.isNotEmpty) {
      () async {
        var prefs = await SharedPreferences.getInstance();
        var tmp = prefs.getString('selectedCourseId');
        if (tmp != null && tmp.isNotEmpty) {
          selectedCourse = _availableCourses.firstWhere((element) => element.id == tmp);
        }
      }();
    }

    return _selectedCourse;
  }

  set selectedCourse(Course? course) {
    if (_selectedCourse != course) {
      _lessons = null;
      _isLessonListLoaded = false;
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
      notifyListeners();
    });
  }

  Future<void> loadLessonList() async {
    // Create courses.
    // FirebaseFirestore.instance.collection('lessons').add(<String, dynamic>{
    //   'courseId': FirebaseFirestore.instance.doc('/courses/4ZUgIakaAbcCiVWMxSKb'),
    //   'sortOrder': 2,
    //   'title': 'First dance',
    //   'instructions': 'Couple work: Basic and inside turn',
    //   'creatorId': auth.FirebaseAuth.instance.currentUser!.uid,
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
}
