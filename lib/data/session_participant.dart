import 'package:cloud_firestore/cloud_firestore.dart';

class SessionParticipant {
  String? id;
  DocumentReference sessionId;
  DocumentReference participantId;
  String participantUid;
  bool isInstructor;

  SessionParticipant(this.id, this.sessionId, this.participantId, this.participantUid,
      this.isInstructor);

  SessionParticipant.fromSnapshot(QueryDocumentSnapshot<Map<String, dynamic>> e)
      : id = e.id,
        sessionId = e.data()['sessionId'] as DocumentReference,
        participantId = e.data()['participantId'] as DocumentReference,
        participantUid = e.data()['participantUid'] as String,
        isInstructor = e.data()['isInstructor'] as bool;
}
