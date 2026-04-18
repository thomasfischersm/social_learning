

import 'package:cloud_firestore/cloud_firestore.dart';

/// A migration tool. In order to query practice records more efficiently, the
/// data was denormalized to add a courseId. These are methods to backfill it
/// and test that the backfill was successful.
class PracticeRecordCourseIdMigration {

  static Future<void> backfillCourseIds() async {

    final firestore = FirebaseFirestore.instance;
    final practiceRecordsRef = firestore.collection('practiceRecords');

    final practiceRecords = await practiceRecordsRef.get();

    for (var record in practiceRecords.docs) {
      try {
        final lessonRef = record['lessonId'] as DocumentReference;
        final lessonSnap = await lessonRef.get();

        if (!lessonSnap.exists) {
          dprint("Lesson not found for PracticeRecord ${record.id}. Lesson is ${lessonRef.id}");
          continue;
        }

        final courseId = lessonSnap['courseId'] as DocumentReference;

        if (record.data().containsKey('courseId')) {
          dprint("Skipping PracticeRecord ${record.id}, already has courseId");
          continue;
        }
        await practiceRecordsRef.doc(record.id).update({
          'courseId': courseId,
        });

        dprint("Updated PracticeRecord ${record.id} with courseId ${courseId.id}");
      } catch (e) {
        dprint("Error processing PracticeRecord ${record.id}: $e");
      }
    }

    dprint("Backfill complete.");
  }

  static Future<void> printPracticeRecordsMissingCourseId() async {
    final firestore = FirebaseFirestore.instance;
    final practiceRecordsRef = firestore.collection('practiceRecords');

    final snapshot = await practiceRecordsRef.get();

    int missingCount = 0;

    for (var doc in snapshot.docs) {
      if (!doc.data().containsKey('courseId')) {
        dprint('PracticeRecord missing courseId: ${doc.id}');
        missingCount++;
      }
    }

    if (missingCount == 0) {
      dprint('✅ All practice records have a courseId.');
    } else {
      dprint('⚠️ $missingCount practice records are missing a courseId.');
    }
  }

  static Future<void> deletePracticeRecordsWithMissingLessons({bool dryRun = true}) async {
    final firestore = FirebaseFirestore.instance;
    final practiceRecordsRef = firestore.collection('practiceRecords');
    final snapshot = await practiceRecordsRef.get();

    int orphanCount = 0;

    for (var record in snapshot.docs) {
      try {
        final lessonRef = record['lessonId'] as DocumentReference;
        final lessonSnap = await lessonRef.get();

        if (!lessonSnap.exists) {
          orphanCount++;
          dprint("Would delete PracticeRecord ${record.id} (lesson ${lessonRef.id} not found)");

          if (!dryRun) {
            // 🔥 Uncomment below to actually delete
            await record.reference.delete();
          }
        }
      } catch (e) {
        dprint("⚠️ Error checking PracticeRecord ${record.id}: $e");
      }
    }

    if (orphanCount == 0) {
      dprint("✅ No orphaned PracticeRecords found.");
    } else {
      dprint("⚠️ Found $orphanCount orphaned PracticeRecords.");
    }
  }
}