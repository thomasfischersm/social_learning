import 'package:cloud_firestore/cloud_firestore.dart';

class Session {
  String? id;
  DocumentReference courseId;
  String name;
  String organizerUid;
  String organizerName;
  int participantCount;
  Timestamp? startTime;
  bool isActive;

  Session(this.id, this.courseId, this.name, this.organizerUid, this.organizerName,
      this.participantCount, this.startTime, this.isActive);

  Session.fromQuerySnapshot(QueryDocumentSnapshot<Map<String, dynamic>> e)
      : id = e.id,
        courseId = e.data()['courseId'] as DocumentReference,
        name = e.data()['name'] as String,
        organizerUid = e.data()['organizerUid'] as String,
        organizerName = e.data()['organizerName'] as String,
        participantCount = e.data()['participantCount'] as int,
        startTime = e.data()['startTime'] as Timestamp?,
        isActive = e.data()['isActive'] as bool;

  Session.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> e)
      : id = e.id,
        courseId = e.data()?['courseId'] as DocumentReference,
        name = e.data()?['name'] as String,
        organizerUid = e.data()?['organizerUid'] as String,
        organizerName = e.data()?['organizerName'] as String,
        participantCount = e.data()?['participantCount'] as int,
        startTime = e.data()?['startTime'] as Timestamp?,
        isActive = e.data()?['isActive'] as bool;
}
