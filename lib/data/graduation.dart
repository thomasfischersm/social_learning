
import 'package:cloud_firestore/cloud_firestore.dart';

@Deprecated('Replaced with practice_record and lesson_status')
class Graduation {
  String id;
  String lessonId;
  String menteeUid;
  String mentorUid;
  Timestamp timestamp;

  Graduation(this.id, this.lessonId, this.menteeUid, this.mentorUid, this.timestamp);

  Graduation.fromSnapshot(QueryDocumentSnapshot<Map<String, dynamic>> e)
      : id = e.id,
        lessonId = e.data()['lessonId'] as String,
        menteeUid = e.data()['menteeUid'] as String,
        mentorUid = e.data()['mentorUid'] as String,
        timestamp = e.data()['timestamp'] as Timestamp;
}