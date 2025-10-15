import 'package:cloud_firestore/cloud_firestore.dart';

class PracticeRecord {
  String id;
  DocumentReference lessonId;
  DocumentReference courseId;
  String menteeUid;
  String mentorUid;
  bool isGraduation;
  List<bool>? graduationRequirementsMet;
  GeoPoint? roughUserLocation;
  Timestamp? timestamp;

  PracticeRecord(this.id, this.lessonId, this.courseId, this.menteeUid, this.mentorUid,
      this.isGraduation, this.roughUserLocation, this.timestamp);

  PracticeRecord.fromSnapshot(QueryDocumentSnapshot<Map<String, dynamic>> e)
      : id = e.id,
        lessonId = e.data()['lessonId'] as DocumentReference,
        courseId = e.data()['courseId'] as DocumentReference,
        menteeUid = e.data()['menteeUid'] as String,
        mentorUid = e.data()['mentorUid'] as String,
        isGraduation = e.data()['isGraduation'] as bool,
        graduationRequirementsMet =
            (e.data()['graduationRequirementsMet'] as List<dynamic>?)
                ?.map((e) => e as bool)
                .toList(),
        roughUserLocation = e.data()['roughUserLocation'] as GeoPoint?,
        timestamp = e.data()['timestamp'] as Timestamp?;
}
