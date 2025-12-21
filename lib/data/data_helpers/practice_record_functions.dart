import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/firestore_service.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/practice_record.dart';

class PracticeRecordFunctions {
  static Future<List<DocumentReference>> getLearnedLessonIds(
      String menteeUid) async {
    // Query the practiceRecords collection for records where the user has graduated.
    QuerySnapshot<Map<String, dynamic>> snapshot = await FirestoreService
        .instance
        .collection('practiceRecords')
        .where('menteeUid', isEqualTo: menteeUid)
        .where('isGraduation', isEqualTo: true)
        .get();
    // TODO: Add filter by course Id.

    // Map the documents to PracticeRecord instances and extract the lessonId.
    List<DocumentReference> lessonIds = snapshot.docs
        .map((doc) => PracticeRecord.fromSnapshot(doc).lessonId)
        .toList();

    return lessonIds;
  }

  /// Returns the count of graduated lessons where [menteeUid] is the student.
  static Future<int> getLessonsLearnedCount(String menteeUid) async {
    final agg = await FirestoreService.instance
        .collection('practiceRecords')
        .where('menteeUid', isEqualTo: menteeUid)
        .where('isGraduation', isEqualTo: true)
        .count()
        .get();
    return agg.count ?? 0;
  }

  /// Returns the count of graduated lessons where [mentorUid] is the instructor.
  static Future<int> getLessonsTaughtCount(String mentorUid) async {
    final agg = await FirestoreService.instance
        .collection('practiceRecords')
        .where('mentorUid', isEqualTo: mentorUid)
        .where('isGraduation', isEqualTo: true)
        .count()
        .get();
    return agg.count ?? 0;
  }

  /// Fetches all practice records (both partial and graduated)
  /// for the given mentee UID.
  static Future<List<PracticeRecord>> fetchPracticeRecordsForMentee(
      String menteeUid) async {
    final snapshot = await FirestoreService.instance
        .collection('practiceRecords')
        .where('menteeUid', isEqualTo: menteeUid)
        .get();

    return snapshot.docs
        .map((doc) => PracticeRecord.fromSnapshot(doc))
        .toList();
  }

  static Query<Map<String, dynamic>>
      practiceRecordsForCourseAndMenteesQuery(
    CollectionReference<Map<String, dynamic>> practiceRecordsCollection,
    Course course,
    List<String> menteeUids,
  ) {
    return practiceRecordsCollection
        .where('courseId', isEqualTo: course.docRef)
        .where('menteeUid', whereIn: menteeUids);
  }

  static Stream<List<PracticeRecord>> listenLessonPracticeRecords({
    required String lessonId,
    required List<String> menteeUids,
  }) {
    if (menteeUids.isEmpty) {
      return const Stream<List<PracticeRecord>>.empty();
    }

    final lessonRef = FirestoreService.instance.doc('lessons/$lessonId');

    return FirestoreService.instance
        .collection('practiceRecords')
        .where('menteeUid', whereIn: menteeUids)
        .where('lessonId', isEqualTo: lessonRef)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PracticeRecord.fromSnapshot(doc))
              .toList(),
        );
  }

  static double getLearnerLessonProgress({
    required Lesson lesson,
    required Iterable<PracticeRecord> practiceRecords,
  }) {
    if (practiceRecords.isEmpty) {
      return 0.0;
    }

    if (practiceRecords.any((record) => record.isGraduation)) {
      return 1.0;
    }

    final PracticeRecord latestRecord = practiceRecords.reduce((a, b) {
      final aTime = a.timestamp?.toDate();
      final bTime = b.timestamp?.toDate();

      if (aTime == null) {
        return b;
      }
      if (bTime == null) {
        return a;
      }

      return aTime.isAfter(bTime) ? a : b;
    });

    final int requirementCount = lesson.graduationRequirements?.length ?? 0;
    if (requirementCount == 0) {
      return 0.5;
    }

    final int metCount = latestRecord.graduationRequirementsMet
            ?.fold<int>(0, (total, met) => total + (met ? 1 : 0)) ??
        0;

    return (metCount / requirementCount).clamp(0.05, 0.95);
  }
}
