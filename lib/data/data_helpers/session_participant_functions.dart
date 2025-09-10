import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/firestore_service.dart';

class SessionParticipantFunctions {
  static Future<DocumentReference<Map<String, dynamic>>> createSessionParticipant({
    required String sessionId,
    required String userId,
    required String participantUid,
    required String courseId,
    required bool isInstructor,
  }) {
    return FirestoreService.instance.collection('sessionParticipants').add({
      'sessionId': FirestoreService.instance.doc('/sessions/$sessionId'),
      'participantId': FirestoreService.instance.doc('/users/$userId'),
      'participantUid': participantUid,
      'courseId': FirestoreService.instance.doc('/courses/$courseId'),
      'isInstructor': isInstructor,
      'isActive': true,
      'teachCount': 0,
      'learnCount': 0,
    });
  }

  static Future<void> updateSessionParticipant(
      String participantId, Map<String, dynamic> data) {
    return FirestoreService.instance
        .doc('/sessionParticipants/$participantId')
        .set(data, SetOptions(merge: true));
  }
}
