import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/practice_record.dart';

class PracticeRecordFunctions {
  static Future<List<DocumentReference>> getLearnedLessonIds(
      String menteeUid) async {
    // Query the practiceRecords collection for records where the user has graduated.
    QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
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
    final agg = await FirebaseFirestore.instance
        .collection('practiceRecords')
        .where('menteeUid', isEqualTo: menteeUid)
        .where('isGraduation', isEqualTo: true)
        .count()
        .get();
    return agg.count ?? 0;
  }

  /// Returns the count of graduated lessons where [mentorUid] is the instructor.
  static Future<int> getLessonsTaughtCount(String mentorUid) async {
    final agg = await FirebaseFirestore.instance
        .collection('practiceRecords')
        .where('mentorUid', isEqualTo: mentorUid)
        .where('isGraduation', isEqualTo: true)
        .count()
        .get();
    return agg.count ?? 0;
  }
}
