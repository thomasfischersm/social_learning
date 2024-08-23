import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:social_learning/data/Level.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:social_learning/data_support/level_sync.dart';

class JsonCurriculumSync {
  static bool _runExportOnce = false;
  static bool _runImportOnce = false;
  static bool _runImportV2Once = false;

  static Future<String?> export() async {
    if (_runExportOnce) {
      print('Export has already run!');
      return Future.value(null);
    } else {
      _runExportOnce = true;
      print('Starting export');
    }

    var db = FirebaseFirestore.instance;
    var lessonDocs = (await db
            .collection('lessons')
            .orderBy('sortOrder', descending: false)
            .get())
        .docs;

    // Parse lessons from the db.
    List<Lesson> lessons = [];
    Map<String, List<Map<String, dynamic>>> levelPathToLessonData = {};
    print('Read ${lessonDocs.length} lessons.');
    for (QueryDocumentSnapshot<Map<String, dynamic>> snapshot in lessonDocs) {
      var lesson = Lesson.fromSnapshot(snapshot);
      lessons.add(lesson);
      var levelPath =
          (lesson.levelId != null) ? '/${lesson.levelId!.path}' : null;

      if (lesson.isLevel == true || (levelPath == null)) {
        // Skip.
        continue;
      }

      var lessonData = {
        'id': lesson.id,
        'courseId': '/${lesson.courseId.path}',
        'levelId': levelPath,
        'title': lesson.title,
        'synopsis': lesson.synopsis,
        'instructions': lesson.instructions,
        'cover': lesson.cover,
        'coverFireStoragePath': lesson.coverFireStoragePath,
        'recapVideo': lesson.recapVideo,
        'lessonVideo': lesson.lessonVideo,
        'practiceVideo': lesson.practiceVideo,
        'graduationRequirements': lesson.graduationRequirements,
      };

      List<Map<String, dynamic>>? lessonList = levelPathToLessonData[levelPath];
      if (lessonList == null) {
        lessonList = [];
        levelPathToLessonData[levelPath] = lessonList;
      }
      lessonList.add(lessonData);
    }

    var levelDocs = (await db
            .collection('levels')
            .orderBy('sortOrder', descending: false)
            .get())
        .docs;

    List<Level> levels = [];
    var levelsData = [];
    Map<String, List<Map<String, dynamic>>> coursePathToLevelData = {};
    for (QueryDocumentSnapshot<Map<String, dynamic>> snapshot in levelDocs) {
      var level = Level.fromQuerySnapshot(snapshot);
      levels.add(level);
      var levelPath = '/levels/${level.id}';
      var coursePath = '/${level.courseId.path}';

      var levelData = {
        'id': level.id,
        'title': level.title,
        'description': level.description,
        'courseId': coursePath,
        'lessons': levelPathToLessonData[levelPath]
      };
      levelsData.add(levelData);

      List<Map<String, dynamic>>? levelList = coursePathToLevelData[coursePath];
      if (levelList == null) {
        levelList = [];
        coursePathToLevelData[coursePath] = levelList;
      }
      levelList.add(levelData);
    }

    var courseDocs = (await db
            .collection('courses')
            .orderBy('title', descending: false)
            .get())
        .docs;

    List<Course> courses = [];
    var coursesData = [];
    for (QueryDocumentSnapshot<Map<String, dynamic>> snapshot in courseDocs) {
      var course = Course.fromSnapshot(snapshot);
      courses.add(course);
      var coursePath = '/courses/${course.id}';

      coursesData.add({
        'id': course.id,
        'title': course.title,
        'description': course.description,
        'levels': coursePathToLevelData[coursePath]
      });
    }

    // Generate JSON.
    JsonEncoder encoder = const JsonEncoder.withIndent('  ');
    var data = {'courses': coursesData};
    var json = encoder.convert(data);
    print(json);
    return json;
  }

  static void import() async {
    if (_runImportOnce) {
      print('Import has already run!');
      return;
    } else {
      _runImportOnce = true;
      print('Starting import');
    }

    String rawJson = await rootBundle.loadString('curriculum.json');
    var json = const JsonDecoder().convert(rawJson);

    var db = FirebaseFirestore.instance;

    // delete
    // Fix course references
    await db.runTransaction((transaction) async {
      var querySnapshot = await db.collection('levels').get();
      for (QueryDocumentSnapshot<Map<String, dynamic>> levelSnapshot
          in querySnapshot.docs) {
        var courseId = levelSnapshot['courseId'];
        if (courseId is String) {
          levelSnapshot.data()['courseId'] = db.doc(courseId);
          Map<String, dynamic> data = {'courseId': db.doc(courseId)};
          transaction.set(
              levelSnapshot.reference, data, SetOptions(merge: true));
          print('fixing course reference');
        }
      }
      print('Done fixing course references');
    });

    db.runTransaction((transaction) async {
      var coursesJson = json['courses'];

      int levelSortOrder = 0;

      QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await db.collection('levels').get();
      Map<String, QueryDocumentSnapshot<Map<String, dynamic>>>
          levelIdToSnapshot = {};
      for (QueryDocumentSnapshot<Map<String, dynamic>> levelSnapshot
          in querySnapshot.docs) {
        levelIdToSnapshot[levelSnapshot.id] = levelSnapshot;
      }

      for (int i = 0; i < coursesJson.length; i++) {
        var courseJson = coursesJson[i];
        print(
            'Course ${courseJson['title']} has ${courseJson['levels']?.length}.');
        var jsonLevels = courseJson['levels'];

        if (jsonLevels != null) {
          for (int i = 0; i < jsonLevels.length; i++) {
            var levelJson = jsonLevels[i];
            var levelId = levelJson['id'];

            if (levelId?.isEmpty ?? true) {
              _createNewLevel(
                  levelJson, courseJson, levelSortOrder, db, transaction);
            } else {
              bool isLevelUpdated = await updateLevel(
                  levelJson,
                  levelIdToSnapshot[levelId]!,
                  courseJson,
                  levelSortOrder,
                  db,
                  transaction);
              levelIdToSnapshot.remove(levelId);
            }

            levelSortOrder++;
          }
        }
      }

      checkForDeletedLevels(levelIdToSnapshot, db, transaction);
    });
  }

  static void _createNewLevel(dynamic levelJson, dynamic courseJson,
      int levelSortOrder, FirebaseFirestore db, transaction) {
    var newLevelRef = db.collection('levels').doc();
    transaction.set(newLevelRef, <String, dynamic>{
      'courseId': db.doc('/courses/${courseJson['id']}'),
      'title': levelJson['title'],
      'description': levelJson['description'],
      'sortOrder': levelSortOrder,
      'creatorId': auth.FirebaseAuth.instance.currentUser!.uid,
    });
    print('Created level ${levelJson['title']}');
  }

  static Future<bool> updateLevel(
      levelJson,
      QueryDocumentSnapshot<Map<String, dynamic>> levelSnapshot,
      courseJson,
      int levelSortOrder,
      FirebaseFirestore db,
      Transaction transaction) async {
    print(' $levelJson');
    Level newLevel = Level.fromJson(levelJson);

    Level currentLevel = Level.fromSnapshot(levelSnapshot);

    print(
        ' EQ: course ${newLevel.courseId == currentLevel.courseId}, title ${newLevel.title == currentLevel.title}, description ${newLevel.description == currentLevel.description}, sortOrder ${levelSortOrder == currentLevel.sortOrder} ($levelSortOrder - ${currentLevel.sortOrder}');
    if ((newLevel.courseId == currentLevel.courseId) &&
        (newLevel.title == currentLevel.title) &&
        (newLevel.description == currentLevel.description) &&
        (levelSortOrder == currentLevel.sortOrder)) {
      return false;
    }

    var docRef = db.collection('levels').doc('${newLevel.id}');
    transaction.set(
        docRef,
        <String, dynamic>{
          'courseId': db.doc('/courses/${courseJson['id']}'),
          'title': levelJson['title'],
          'description': levelJson['description'],
          'sortOrder': levelSortOrder,
          'creatorId': auth.FirebaseAuth.instance.currentUser!.uid,
        },
        SetOptions(merge: true));

    print('Updated level ${newLevel.title}');
    return true;
  }

  static void checkForDeletedLevels(
      Map<String, QueryDocumentSnapshot<Map<String, dynamic>>>
          levelIdToSnapshot,
      FirebaseFirestore db,
      Transaction transaction) {
    for (QueryDocumentSnapshot<Map<String, dynamic>> levelSnapshot
        in levelIdToSnapshot.values) {
      var level = Level.fromQuerySnapshot(levelSnapshot);
      var docRef = db.collection('levels').doc('${level.id}');
      transaction.delete(docRef);

      print('Deleted level ${level.title}');
    }
  }

  static convertTextToJson(String fileName, String courseId) async {
    String txt = await rootBundle.loadString(fileName);

    List<Map<String, dynamic>> levelsData = [];
    List<Map<String, dynamic>> currentLessonsData = [];
    for (String line in txt.replaceAll('\r', '').split('\n')) {
      if (line.startsWith('Level')) {
        // Add level.
        var title = line.substring(line.indexOf('-') + 2);
        currentLessonsData = [];
        Map<String, dynamic> level = {
          'title': title,
          'description': '',
          'courseId': courseId,
          'lessons': currentLessonsData
        };
        levelsData.add(level);
      } else {
        // Add lesson.
        Map<String, dynamic> lesson = {
          'courseId': courseId,
          'title': line,
          'synopsis': '',
          'instructions': '',
        };
        currentLessonsData.add(lesson);
      }
    }

    JsonEncoder encoder = const JsonEncoder.withIndent('  ');
    var data = {'levels': levelsData};
    var json = encoder.convert(data);
    print(json);
  }

  static void importV2() async {
    if (_runImportV2Once) {
      print('Import V2 has already run!');
      return;
    } else {
      _runImportV2Once = true;
      print('Starting import V2');
    }

    String rawJson = await rootBundle.loadString('curriculum.json');
    var json = const JsonDecoder().convert(rawJson);

    var db = FirebaseFirestore.instance;

    // DELETE: trash collections
    // await db.runTransaction((transaction) async {
    //   var querySnapshot = await db.collection('lessons').get();
    //   for (QueryDocumentSnapshot<Map<String, dynamic>> doc in querySnapshot.docs) {
    //     transaction.delete(doc.reference);
    //     print('Delete old lesson');
    //   }
    // });

    db.runTransaction((transaction) async {
      var levelSync = LevelSync(transaction);

      var coursesJson = json['courses'];
      for (int i = 0; i < coursesJson.length; i++) {
        var courseJson = coursesJson[i];
        print(
            'Course ${courseJson['title']} has ${courseJson['levels']?.length}.');
        // print('get dynamic type: ${courseJson['levels'].runtimeType}');
        // print('levels are: ${courseJson['levels']}');
        List<dynamic>? jsonLevels = courseJson['levels'];

        if (jsonLevels != null) {
          await levelSync.sync(jsonLevels, '/courses/${courseJson['id']}',
              i == coursesJson.length - 1);
        }
      }
    });
  }
}
