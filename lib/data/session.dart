import 'package:cloud_firestore/cloud_firestore.dart';

import 'session_type.dart';
export 'session_type.dart';

class Session {
  String? id;
  DocumentReference courseId;
  String name;
  String organizerUid;
  String organizerName;
  int participantCount;
  Timestamp? startTime;
  bool isActive;
  SessionType sessionType;
  bool includeHostInPairing;

  Session(
      this.id,
      this.courseId,
      this.name,
      this.organizerUid,
      this.organizerName,
      this.participantCount,
      this.startTime,
      this.isActive,
      this.sessionType,
      this.includeHostInPairing);

  Session.fromQuerySnapshot(QueryDocumentSnapshot<Map<String, dynamic>> e)
      : id = e.id,
        courseId = e.data()['courseId'] as DocumentReference,
        name = e.data()['name'] as String,
        organizerUid = e.data()['organizerUid'] as String,
        organizerName = e.data()['organizerName'] as String,
        participantCount = e.data()['participantCount'] as int,
        startTime = e.data()['startTime'] as Timestamp?,
        isActive = e.data()['isActive'] as bool,
        sessionType = SessionType.fromInt(e.data()['sessionType'] as int?),
        includeHostInPairing =
            (e.data()['includeHostInPairing'] as bool?) ?? true;

  Session.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> e)
      : id = e.id,
        courseId = e.data()?['courseId'] as DocumentReference,
        name = e.data()?['name'] as String,
        organizerUid = e.data()?['organizerUid'] as String,
        organizerName = e.data()?['organizerName'] as String,
        participantCount = e.data()?['participantCount'] as int,
        startTime = e.data()?['startTime'] as Timestamp?,
        isActive = e.data()?['isActive'] as bool,
        sessionType = SessionType.fromInt(e.data()?['sessionType'] as int?),
        includeHostInPairing =
            (e.data()?['includeHostInPairing'] as bool?) ?? true;
}
