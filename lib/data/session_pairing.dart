import 'package:cloud_firestore/cloud_firestore.dart';

class SessionPairing {
  String? id;
  DocumentReference sessionId;
  int roundNumber;
  DocumentReference mentorId;
  DocumentReference learnerId;
  DocumentReference lessonId;

  SessionPairing(this.id, this.sessionId, this.roundNumber, this.mentorId,
      this.learnerId, this.lessonId);

  SessionPairing.fromSnapshot(QueryDocumentSnapshot<Map<String, dynamic>> e)
      : id = e.id,
        sessionId = e.data()['sessionId'] as DocumentReference,
        roundNumber = e.data()['roundNumber'] as int,
        mentorId = e.data()['mentorId'] as DocumentReference,
        learnerId = e.data()['learnerId'] as DocumentReference,
        lessonId = e.data()['lessonId'] as DocumentReference;
}
