
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/Level.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

/// Migrates the db version where levels were a type of lesson to where it's
/// a high level object.
class LevelMigration {
  static bool _runOnce = false;

  static void migrate() async {
    if (_runOnce) {
      print('Already run!');
      return;
    } else {
      _runOnce = true;
      print('Starting migration');
    }

    var db = FirebaseFirestore.instance;

    db.runTransaction((transaction) async {
      var docs = (await db.collection('lessons').get()).docs;
      for (var element in docs) {
        print('about to clear level ${element.get('title')}');
        if (element.data().keys.contains('levelId') &&
            element.get('levelId') is String) {
          transaction.set(element.reference,
              {'levelId': null, 'creatorId': element.get('creatorId')}, SetOptions(merge: true));
          print('Cleared level id ${element.get('title')}');
        }
      }

      print('Done resetting levelId.');
    });

    // Test permissions
    // var doc = db.collection('levels').doc();
    // doc.set({
    //   'title': 'DELETE!',
    //   'description': 'desc',
    //   'sortOrder': 0,
    //   'creatorId': auth.FirebaseAuth.instance.currentUser!.uid,
    // }).onError((e, _) => print("222Error writing document: $e"));
    // print('Tested writing to levels');

    db.runTransaction((transaction) async {
      print('Starting transaction');

      // Delete all previous levels.
      var oldLevels = await db.collection('levels').get();
      for (QueryDocumentSnapshot snapshot in oldLevels.docs) {
        print('Delete level: ${snapshot.get('title')}');
        transaction.delete(snapshot.reference);
      }

      final lessons = await db
          .collection('lessons')
          .orderBy('sortOrder', descending: false)
          .get();
      print('Got ${lessons.size} lessons.');

      int levelCount = 0;
      String lastLevelId = '';

      // for (int i = 0; i < lessons.length; i++) {
      //   var lessonSnapshot = lessons[i];
      var docs = lessons.docs;
      print('got ${docs.length} docs.');
      for (int j = 0; j < docs.length; j++) {
        var lessonDoc = docs[j];
        if (lessonDoc.data().keys.contains('levelId') &&
            lessonDoc.get('levelId') is String) {
          // Resetting levelId to null.
          lessonDoc.data().update('levelId', (value) => null);
        }
        Lesson lesson = Lesson.fromSnapshot(lessonDoc);

        if (lesson.isLevel) {
          // Create a new level.
          print('Creating level: ${lesson.title}');
          var newLevelRef = db.collection('levels').doc();
          Level newLevel = Level(newLevelRef.id, lesson.courseId, lesson.title,
              '', levelCount, auth.FirebaseAuth.instance.currentUser!.uid);
          transaction.set(newLevelRef, <String, dynamic>{
            'courseId': newLevel.courseId,
            'title': newLevel.title,
            'description': newLevel.description,
            'sortOrder': newLevel.sortOrder,
            'creatorId': auth.FirebaseAuth.instance.currentUser!.uid,
          });

          lastLevelId = newLevelRef.id;
          levelCount++;
        } else {
          // Update the level reference.
          print('Updating lesson to refer to level.');
          var lessonDocRef = db.collection('lessons').doc(lesson.id);
          transaction.update(lessonDocRef, {
            'levelId': FirebaseFirestore.instance.doc('/levels/$lastLevelId')
          });
        }
        // }
      }

      print('Ready to commit transaction');
    }).then(
      (value) => print("DocumentSnapshot successfully updated!"),
      onError: (e) {
        print("Error updating document $e ${e.runtimeType}");
        print('${e.stackTrace}');
      },
    );

    print('kicked off migration');
  }
}
