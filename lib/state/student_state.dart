import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social_learning/data/Level.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/lesson_status.dart';
import 'package:social_learning/data/practice_record.dart';
import 'package:social_learning/data/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:social_learning/data/user_functions.dart';
import 'package:social_learning/state/library_state.dart';

class StudentState extends ChangeNotifier {
  bool _isInitialized = false;
  List<PracticeRecord>? _learnRecords;
  List<PracticeRecord>? _teachRecords;

  // List<LessonStatus>? _lessonStatuses;

  void _init() {
    if (!_isInitialized) {
      _isInitialized = true;

      FirebaseFirestore.instance
          .collection('practiceRecords')
          .where('menteeUid',
              isEqualTo: auth.FirebaseAuth.instance.currentUser?.uid)
          .snapshots()
          .listen((snapshot) {
        _learnRecords =
            snapshot.docs.map((e) => PracticeRecord.fromSnapshot(e)).toList();
        notifyListeners();
      });

      FirebaseFirestore.instance
          .collection('practiceRecords')
          .where('mentorUid',
              isEqualTo: auth.FirebaseAuth.instance.currentUser?.uid)
          .snapshots()
          .listen((snapshot) {
        _teachRecords =
            snapshot.docs.map((e) => PracticeRecord.fromSnapshot(e)).toList();
        notifyListeners();
      });
    }
  }

  bool hasGraduated(Lesson? lesson) {
    if (lesson == null) {
      return false;
    }

    _init();
    return _learnRecords?.any((element) =>
            (element.lessonId == lesson.id) && (element.isGraduation)) ??
        false;
  }

  void recordTeaching(Lesson lesson, User mentee, bool isGraduation) {
    var data = <String, dynamic>{
      'lessonId': lesson.id,
      'menteeUid': mentee.uid,
      'mentorUid': auth.FirebaseAuth.instance.currentUser?.uid,
      'isGraduation': isGraduation,
      'timestamp': FieldValue.serverTimestamp(),
    };
    FirebaseFirestore.instance.collection('practice_record').add(data);
  }

  int getPracticeCount() => _learnRecords?.length ?? 0;

  int getGraduationCount() =>
      _learnRecords?.fold(
          0,
          (previousValue, element) => previousValue =
              previousValue! + (element.isGraduation ? 1 : 0)) ??
      0;

  int getTeachCount() => _teachRecords?.length ?? 0;

  /// Returns 0 for never practice, 1 for practiced, 2 for graduated, and 3 for
  /// taught.
  int getLessonStatus(Lesson lesson) {
    var learnRecords = _learnRecords;

    bool hasPracticed = false;
    bool hasGraduated = false;
    bool hasTaught = false;

    if (learnRecords != null) {
      for (PracticeRecord record in learnRecords) {
        if (record.lessonId == lesson.id) {
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
          if (record.lessonId == lesson.id) {
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

    for (Lesson lesson in lessons) {
      if (lesson.isLevel) {
        continue;
      }

      int levelId = UserFunctions.extractNumberId(lesson.levelId)!;
      LevelCompletion? levelCompletion =
          levelIdToCompletionMap[levelId.toString()];

      if (levelCompletion != null) {
        levelCompletion.lessonIds.add(int.parse(lesson.id));
        lessonIdToCompletionMap[lesson.id] = levelCompletion;
      }
    }

    var learnRecords = _learnRecords;
    if (learnRecords != null) {
      for (PracticeRecord practiceRecord in learnRecords) {
        int lessonId = UserFunctions.extractNumberId(practiceRecord.lessonId)!;
        lessonIdToCompletionMap[lessonId.toString()]
            ?.graduatedLessonIds
            .add(lessonId);
      }
    }

    return levelCompletions;
  }

  LessonCount getCountsForLesson(Lesson lesson) {
    _init();

    LessonCount lessonCount = LessonCount();
    var learnRecords = _learnRecords;
    if (learnRecords != null) {
      for (PracticeRecord record in learnRecords) {
        if (record.lessonId.id.endsWith('/${lesson.id}')) {
          lessonCount.practiceCount++;
          lessonCount.isGraduated =
              lessonCount.isGraduated || record.isGraduation;
        }
      }
    }

    var teachRecords = _teachRecords;
    if (teachRecords != null) {
      for (PracticeRecord record in teachRecords) {
        if (record.lessonId.id.endsWith('/${lesson.id}')) {
          lessonCount.teachCount++;
        }
      }
    }

    return lessonCount;
  }
}

class LevelCompletion {
  Level level;

  int get lessonCount => lessonIds.length;

  int get lessonsGraduatedCount => graduatedLessonIds.length;

  bool get isLevelGraduated =>
      (lessonCount == lessonsGraduatedCount) && (lessonCount > 0);
  Set<int> lessonIds = {};
  Set<int> graduatedLessonIds = {};

  LevelCompletion(this.level);
}

class LessonCount {
  int practiceCount = 0;
  int teachCount = 0;
  bool isGraduated = false;
}