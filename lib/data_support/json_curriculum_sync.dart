import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:social_learning/data/Level.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/lesson.dart';

class JsonCurriculumSync {

  static bool _runOnce = false;

  static void export() async {
    if (_runOnce) {
      print('Export has already run!');
      return;
    } else {
      _runOnce = true;
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
      var levelPath = (lesson.levelId != null) ? '/${lesson.levelId!.path}' : null;

      if (lesson.isLevel || (levelPath == null)) {
        // Skip.
        continue;
      }

      var lessonData = {
        'id': lesson.id,
        'courseId': '/${lesson.courseId.path}',
        'levelId': '/$levelPath',
        'title': lesson.title,
        'synopsis': lesson.synopsis,
        'instructions': lesson.instructions,
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
      var level = Level.fromSnapshot(snapshot);
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
  }

  void import() async {
    String json = await rootBundle.loadString('assets/curriculum');
  }
}
