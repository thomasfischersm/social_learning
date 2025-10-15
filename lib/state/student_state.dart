import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/Level.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/practice_record.dart';
import 'package:social_learning/data/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:social_learning/data/data_helpers/user_functions.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';

class StudentState extends ChangeNotifier {
  final ApplicationState _applicationState;
  final LibraryState _libraryState;

  bool _isInitialized = false;
  List<PracticeRecord>? _learnRecords;
  List<PracticeRecord>? _teachRecords;
  StreamSubscription? _menteeSubscription;
  StreamSubscription? _mentorSubscription;

  // Cache the progress state for each lesson.
  final Map<String, LessonCount> _lessonIdToLessonCountMap = {};

  StudentState(this._applicationState, this._libraryState);

  void _init() {
    if (!_isInitialized) {
      _isInitialized = true;

      _menteeSubscription = FirebaseFirestore.instance
          .collection('practiceRecords')
          .where('menteeUid',
              isEqualTo: auth.FirebaseAuth.instance.currentUser?.uid)
          .snapshots()
          .listen((snapshot) {
        _learnRecords =
            snapshot.docs.map((e) => PracticeRecord.fromSnapshot(e)).toList();

        UserFunctions.updateCourseProficiency(
            _applicationState, _libraryState, this);

        _recomputeLessonCountCache();

        notifyListeners();
      });

      _mentorSubscription = FirebaseFirestore.instance
          .collection('practiceRecords')
          .where('mentorUid',
              isEqualTo: auth.FirebaseAuth.instance.currentUser?.uid)
          .snapshots()
          .listen((snapshot) {
        _teachRecords =
            snapshot.docs.map((e) => PracticeRecord.fromSnapshot(e)).toList();
        _recomputeLessonCountCache();
        notifyListeners();
      });

      _libraryState.addListener(
        () {
          _recomputeLessonCountCache();
          UserFunctions.updateCourseProficiency(
              _applicationState, _libraryState, this);

          notifyListeners();
        },
      );
    }
  }

  void _recomputeLessonCountCache() {
    _lessonIdToLessonCountMap.clear();

    Course? course = _libraryState.selectedCourse;
    if (course == null) {
      return;
    }

    var learnRecords = _learnRecords;
    if (learnRecords != null) {
      for (PracticeRecord record in learnRecords) {
        if (record.courseId.id != course.id) {
          continue;
        }

        var lessonCount = _lessonIdToLessonCountMap.putIfAbsent(
            record.lessonId.id, () => LessonCount());
        lessonCount.practiceCount++;
        lessonCount.isGraduated =
            lessonCount.isGraduated || record.isGraduation;
      }
    }

    var teachRecords = _teachRecords;
    if (teachRecords != null) {
      for (PracticeRecord record in teachRecords) {
        if (record.courseId.id != course.id) {
          continue;
        }

        var lessonCount = _lessonIdToLessonCountMap.putIfAbsent(
            record.lessonId.id, () => LessonCount());
        lessonCount.teachCount++;
      }
    }
  }

  bool hasGraduated(Lesson? lesson) {
    if (lesson == null) {
      return false;
    }

    _init();
    return _lessonIdToLessonCountMap[lesson.id]?.isGraduated ?? false;
  }

  void recordTeachingWithCheck(
      Lesson lesson, User mentee, bool isGraduation, BuildContext context) {
    var hasGraduated = (getLessonStatus(lesson) > 1);
    var isAdmin = (Provider.of<ApplicationState>(context, listen: false)
            .currentUser
            ?.isAdmin ??
        false);
    if (hasGraduated || isAdmin) {
      print('Recording practiceRecord.');
      recordTeaching(lesson.id!, lesson.courseId.id, mentee, isGraduation);
    } else {
      print('Silently discarding practiceRecord ${getLessonStatus(lesson)}');
    }
  }

  void recordTeaching(
      String lessonId, String courseId, User mentee, bool isGraduation) async {
    var data = <String, dynamic>{
      'lessonId': FirebaseFirestore.instance.doc('lessons/$lessonId'),
      'courseId': FirebaseFirestore.instance.doc('courses/$courseId'),
      'menteeUid': mentee.uid,
      'mentorUid': auth.FirebaseAuth.instance.currentUser?.uid,
      'isGraduation': isGraduation,
      'timestamp': FieldValue.serverTimestamp(),
    };

    if (mentee.isGeoLocationEnabled &&
        mentee.location != null &&
        isGraduation) {
      data['roughUserLocation'] = mentee.location;
    }

    await FirebaseFirestore.instance.collection('practiceRecords').add(data);
  }

  int getPracticeCount() => _learnRecords?.length ?? 0;

  int getPracticeCountForSelectedCourse() {
    _init();

    final selectedCourse = _libraryState.selectedCourse;
    final courseId = selectedCourse?.id;
    if (selectedCourse == null || courseId == null) {
      return 0;
    }

    return _learnRecords
            ?.where((record) => record.courseId.id == courseId)
            .length ??
        0;
  }

  int getGraduationCount() =>
      _learnRecords?.fold(
          0,
          (previousValue, element) => previousValue =
              previousValue! + (element.isGraduation ? 1 : 0)) ??
      0;

  int getGraduationCountForSelectedCourse() {
    _init();

    final selectedCourse = _libraryState.selectedCourse;
    final courseId = selectedCourse?.id;
    if (selectedCourse == null || courseId == null) {
      return 0;
    }

    return _learnRecords
            ?.where((record) =>
                record.courseId.id == courseId && record.isGraduation)
            .length ??
        0;
  }

  int getTeachCount() => _teachRecords?.length ?? 0;

  int getTeachCountForSelectedCourse() {
    _init();

    final selectedCourse = _libraryState.selectedCourse;
    final courseId = selectedCourse?.id;
    if (selectedCourse == null || courseId == null) {
      return 0;
    }

    return _teachRecords
            ?.where((record) => record.courseId.id == courseId)
            .length ??
        0;
  }

  Map<String, int> getSelectedCourseLessonStatuses() {
    _init();

    final selectedCourse = _libraryState.selectedCourse;
    final courseId = selectedCourse?.id;
    if (selectedCourse == null || courseId == null) {
      return const {};
    }

    final lessonStatuses = <String, int>{};

    void updateStatus(String lessonId, int newStatus) {
      final current = lessonStatuses[lessonId];
      if (current == null || newStatus > current) {
        lessonStatuses[lessonId] = newStatus;
      }
    }

    final learnRecords = _learnRecords;
    if (learnRecords != null) {
      for (final record in learnRecords) {
        if (record.courseId.id != courseId) {
          continue;
        }

        final lessonId = record.lessonId.id;
        updateStatus(lessonId, record.isGraduation ? 2 : 1);
      }
    }

    final teachRecords = _teachRecords;
    if (teachRecords != null) {
      for (final record in teachRecords) {
        if (!record.isGraduation) {
          continue;
        }
        if (record.courseId.id != courseId) {
          continue;
        }

        final lessonId = record.lessonId.id;
        if ((lessonStatuses[lessonId] ?? 0) >= 2) {
          updateStatus(lessonId, 3);
        }
      }
    }

    return Map.unmodifiable(lessonStatuses);
  }

  /// Returns 0 for never practice, 1 for practiced, 2 for graduated, and 3 for
  /// taught.
  int getLessonStatus(Lesson lesson) {
    _init();

    var lessonCount = _lessonIdToLessonCountMap[lesson.id];
    if (lessonCount == null) {
      return 0;
    } else if (lessonCount.teachCount > 0) {
      return 3;
    } else if (lessonCount.isGraduated) {
      return 2;
    } else if (lessonCount.practiceCount > 0) {
      return 1;
    } else {
      return 0;
    }
  }

  List<LevelCompletion> getLevelCompletions(LibraryState libraryState) {
    _init();
    var levels = libraryState.levels;
    if (levels == null) {
      return [];
    }

    var lessons = libraryState.lessons;
    if (lessons == null) {
      return [];
    }

    List<LevelCompletion> levelCompletions = [];
    Map<String, LevelCompletion> levelIdToCompletionMap = {};
    Map<String, LevelCompletion> lessonIdToCompletionMap = {};
    for (Level level in levels) {
      var levelCompletion = LevelCompletion(level);
      levelCompletions.add(levelCompletion);
      var levelId = level.id;
      if (levelId != null) {
        levelIdToCompletionMap[levelId] = levelCompletion;
      }
    }

    // Handle flex lessons.
    const String flexLessonsLevelId = 'flex Lessons';
    var flexLevelCompletion = LevelCompletion(Level(
        flexLessonsLevelId,
        FirebaseFirestore.instance
            .doc('/courses/${libraryState.selectedCourse!.id}'),
        'Flex Lessons',
        '',
        999999,
        ''));
    levelCompletions.add(flexLevelCompletion);
    levelIdToCompletionMap[flexLessonsLevelId] = flexLevelCompletion;

    for (Lesson lesson in lessons) {
      if (lesson.isLevel == true) {
        continue;
      }

      String levelId =
          UserFunctions.extractNumberId(lesson.levelId) ?? flexLessonsLevelId;
      LevelCompletion? levelCompletion = levelIdToCompletionMap[levelId];

      if (levelCompletion != null) {
        levelCompletion.lessonRawIds.add(lesson.id!);
        lessonIdToCompletionMap[lesson.id!] = levelCompletion;
      }
    }

    var learnRecords = _learnRecords;
    if (learnRecords != null) {
      for (PracticeRecord practiceRecord in learnRecords) {
        if (practiceRecord.isGraduation) {
          String lessonRawId =
              UserFunctions.extractNumberId(practiceRecord.lessonId)!;
          lessonIdToCompletionMap[lessonRawId.toString()]
              ?.graduatedLessonRawIds
              .add(lessonRawId);
        }
      }
    }

    // Remove Flex lessons if it is empty.
    if (flexLevelCompletion.lessonCount == 0) {
      levelCompletions.remove(flexLevelCompletion);
    }

    return levelCompletions;
  }

  LessonCount getCountsForLesson(Lesson lesson) {
    _init();
    print('getCountsForLesson for ${lesson.title}');

    return _lessonIdToLessonCountMap[lesson.id] ?? LessonCount();
  }

  double getLessonCompletionPercent(Lesson lesson) {
    List<PracticeRecord>? lessonLearnRecords = _learnRecords
        ?.where((element) => element.lessonId.id == lesson.id)
        .toList();

    if (lessonLearnRecords == null || lessonLearnRecords.isEmpty) {
      return 0;
    } else if (lessonLearnRecords.any((element) => element.isGraduation)) {
      return 1;
    } else {
      PracticeRecord lastRecord = lessonLearnRecords.reduce((a, b) {
        final aTime = a.timestamp?.toDate();
        final bTime = b.timestamp?.toDate();

        if (aTime == null) return b;
        if (bTime == null) return a;

        return aTime.isAfter(bTime) ? a : b;
      });
      return 0.5; // Todo: implement looking at graduation requirements.
    }
  }

  double getLevelCompletionPercent(Level level) {
    String? levelId = level.id;
    if (levelId == null) {
      return 0;
    }

    Iterable<Lesson> lessons = (level.title == 'Flex Lessons')
        ? _libraryState.getUnattachedLessons()
        : _libraryState.getLessonsByLevel(levelId);
    double sum = lessons.fold(
        0, (total, lesson) => total + getLessonCompletionPercent(lesson));
    print(
        'getLevelCompletionPercent for ${level.title} is ${sum / lessons.length} and $sum and ${lessons.length}');
    return sum / lessons.length;
  }

  @visibleForTesting
  void setPracticeRecords(
      {List<PracticeRecord>? learnRecords,
      List<PracticeRecord>? teachRecords}) {
    _learnRecords = learnRecords;
    _teachRecords = teachRecords;
  }

  void signOut() {
    _menteeSubscription?.cancel();
    _mentorSubscription?.cancel();

    _isInitialized = false;
    _learnRecords = null;
    _teachRecords = null;
    _lessonIdToLessonCountMap.clear();
  }

  int getLessonsLearned(Course course, LibraryState libraryState) {
    _init();

    return _lessonIdToLessonCountMap.values
        .where((element) => element.isGraduated)
        .length;
  }

  List<String> getGraduatedLessonIds() {
    _init();

    return _lessonIdToLessonCountMap.entries
        .where((element) => element.value.isGraduated)
        .map((e) => e.key)
        .toList();
  }

  bool canTeachInCurrentCourse() {
    _init();

    return _lessonIdToLessonCountMap.values
        .any((element) => element.isGraduated);
  }
}

class LevelCompletion {
  Level level;

  int get lessonCount => lessonRawIds.length;

  int get lessonsGraduatedCount => graduatedLessonRawIds.length;

  bool get isLevelGraduated =>
      (lessonCount == lessonsGraduatedCount) && (lessonCount > 0);
  Set<String> lessonRawIds = {};
  Set<String> graduatedLessonRawIds = {};

  LevelCompletion(this.level);
}

class LessonCount {
  int practiceCount = 0;
  int teachCount = 0;
  bool isGraduated = false;
}
