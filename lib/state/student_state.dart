import 'dart:async';

import 'package:collection/collection.dart';
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
        notifyListeners();
      });

      _libraryState.addListener(
        () {
          UserFunctions.updateCourseProficiency(
              _applicationState, _libraryState, this);

          notifyListeners();
        },
      );
    }
  }

  bool hasGraduated(Lesson? lesson) {
    if (lesson == null) {
      return false;
    }

    _init();
    return _learnRecords?.any((element) =>
            (element.lessonId.id == lesson.id) && (element.isGraduation)) ??
        false;
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

  int getGraduationCount() =>
      _learnRecords?.fold(
          0,
          (previousValue, element) => previousValue =
              previousValue! + (element.isGraduation ? 1 : 0)) ??
      0;

  int getTeachCount() => _teachRecords?.length ?? 0;

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
    var learnRecords = _learnRecords;

    bool hasPracticed = false;
    bool hasGraduated = false;
    bool hasTaught = false;

    if (learnRecords != null) {
      for (PracticeRecord record in learnRecords) {
        if (record.lessonId.id == lesson.id) {
          if (record.isGraduation) {
            hasGraduated = true;
            hasPracticed = true;
            break;
          }
          hasPracticed = true;
        }
      }
    }

    if (hasGraduated) {
      var teachRecords = _teachRecords;
      if (teachRecords != null) {
        for (PracticeRecord record in teachRecords) {
          if (record.lessonId.id == lesson.id) {
            if (record.isGraduation) {
              hasTaught = true;
              break;
            }
          }
        }
      }
    }

    if (hasTaught) {
      return 3;
    } else if (hasGraduated) {
      return 2;
    } else if (hasPracticed) {
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

    LessonCount lessonCount = LessonCount();
    var learnRecords = _learnRecords;
    if (learnRecords != null) {
      for (PracticeRecord record in learnRecords) {
        if (record.lessonId.id == lesson.id) {
          lessonCount.practiceCount++;
          lessonCount.isGraduated =
              lessonCount.isGraduated || record.isGraduation;
        } else {
          print(
              'lesson id didn\'t match ${record.lessonId.id} and ${lesson.id}');
        }
      }
    }

    var teachRecords = _teachRecords;
    if (teachRecords != null) {
      for (PracticeRecord record in teachRecords) {
        if (record.lessonId.id == lesson.id) {
          lessonCount.teachCount++;
        }
      }
    }

    return lessonCount;
  }

  @visibleForTesting
  void setPracticeRecords({List<PracticeRecord>? learnRecords, List<PracticeRecord>? teachRecords}) {
    _learnRecords = learnRecords;
    _teachRecords = teachRecords;
  }

  void signOut() {
    _menteeSubscription?.cancel();
    _mentorSubscription?.cancel();

    _isInitialized = false;
    _learnRecords = null;
    _teachRecords = null;
  }

  int getLessonsLearned(Course course, LibraryState libraryState) {
    _init();

    int learnCount = 0;

    Set<String> alreadyCountedLessonIds = {};

    var learnRecords = _learnRecords;
    if (learnRecords != null) {
      for (PracticeRecord record in learnRecords) {
        Lesson? lesson = libraryState.lessons
            ?.firstWhereOrNull((element) => element.id == record.lessonId.id);

        if ((lesson == null) || (lesson.courseId.id != course.id)) {
          continue;
        }

        if (alreadyCountedLessonIds.contains(lesson.id)) {
          continue;
        }

        if (record.isGraduation) {
          alreadyCountedLessonIds.add(lesson.id!);
          learnCount++;
        }
      }
    }
    return learnCount;
  }

  List<String> getGraduatedLessonIds() {
    if (!_libraryState.isCourseSelected) {
      return [];
    }

    _init();

    List<String> graduatedLessonIds = [];
    List<PracticeRecord>? learnRecords = _learnRecords;
    Course? selectedCourse = _libraryState.selectedCourse;

    if ((learnRecords == null) || (selectedCourse == null)) {
      return [];
    }

    for (PracticeRecord record in learnRecords) {
      Lesson? lesson = _libraryState.findLesson(record.lessonId.id);

      if ((lesson == null) || (lesson.courseId.id != selectedCourse.id)) {
        // The PracticeRecord is not relevant.
        continue;
      }

      if (record.isGraduation) {
        graduatedLessonIds.add(lesson.id!);
      }
    }

    return graduatedLessonIds;
  }

  bool canTeachInCurrentCourse() {
    if (!_libraryState.isCourseSelected) {
      return false;
    }

    _init();

    Course? selectedCourse = _libraryState.selectedCourse;
    if (selectedCourse == null) {
      return false;
    }

    return _learnRecords?.any((element) =>
            element.isGraduation &&
            (_libraryState.findLesson(element.lessonId.id)?.courseId.id ==
                selectedCourse.id)) ??
        false;
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
