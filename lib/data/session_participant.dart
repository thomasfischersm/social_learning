import 'package:cloud_firestore/cloud_firestore.dart';

class SessionParticipant {
  String? id;
  DocumentReference sessionId;
  DocumentReference participantId;
  String participantUid;
  bool isInstructor;
  bool isActive;
  int teachCount;
  int learnCount;

  SessionParticipant(
      this.id,
      this.sessionId,
      this.participantId,
      this.participantUid,
      this.isInstructor,
      this.isActive,
      this.teachCount,
      this.learnCount);

  SessionParticipant.fromSnapshot(QueryDocumentSnapshot<Map<String, dynamic>> e)
      : id = e.id,
        sessionId = e.data()['sessionId'] as DocumentReference,
        participantId = e.data()['participantId'] as DocumentReference,
        participantUid = e.data()['participantUid'] as String,
        isInstructor = e.data()['isInstructor'] as bool,
        isActive = e.data()['isActive'] as bool,
        teachCount = e.data()['teachCount'] as int? ?? 0,
        learnCount = e.data()['learnCount'] as int? ?? 0;
}
