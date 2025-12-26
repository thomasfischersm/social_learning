import 'package:cloud_firestore/cloud_firestore.dart';

class SessionPairing {
  String? id;
  DocumentReference sessionId;
  int roundNumber;
  DocumentReference? mentorId;
  DocumentReference? menteeId;
  DocumentReference? lessonId;
  List<DocumentReference> additionalStudentIds;
  bool isCompleted;
  Timestamp? completeAt;

  SessionPairing(this.id, this.sessionId, this.roundNumber, this.mentorId,
      this.menteeId, this.lessonId,
      [this.additionalStudentIds = const [],
      this.isCompleted = false]);

  SessionPairing.fromSnapshot(QueryDocumentSnapshot<Map<String, dynamic>> e)
      : id = e.id,
        sessionId = e.data()['sessionId'] as DocumentReference,
        roundNumber = e.data()['roundNumber'] as int,
        mentorId = e.data()['mentorId'] as DocumentReference?,
        menteeId = e.data()['menteeId'] as DocumentReference?,
        lessonId = e.data()['lessonId'] as DocumentReference?,
        additionalStudentIds = e.data().containsKey('additionalStudentIds')
            ? List<DocumentReference>.from(
                e.data()['additionalStudentIds'] as List<dynamic>)
            : [],
        isCompleted = e.data()['isCompleted'] as bool? ?? false,
        completeAt = e.data()['completeAt'] as Timestamp?;
}
