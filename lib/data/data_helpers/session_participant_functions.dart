import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/data_helpers/reference_helper.dart';
import 'package:social_learning/data/firestore_service.dart';
import 'package:social_learning/data/session_participant.dart';

class SessionParticipantFunctions {
  static Query<Map<String, dynamic>> queryBySessionId(
      CollectionReference<Map<String, dynamic>> collectionReference,
      String sessionId) {
    return collectionReference.where('sessionId',
        isEqualTo: docRef('sessions', sessionId));
  }

  static Future<DocumentReference<Map<String, dynamic>>> createParticipant({
    required String sessionId,
    required String userId,
    required String userUid,
    required String courseId,
    required bool isInstructor,
    bool isActive = true,
    int teachCount = 0,
    int learnCount = 0,
  }) {
    return FirestoreService.instance.collection('sessionParticipants').add({
      'sessionId': docRef('sessions', sessionId),
      'participantId': docRef('users', userId),
      'participantUid': userUid,
      'courseId': docRef('courses', courseId),
      'isInstructor': isInstructor,
      'isActive': isActive,
      'teachCount': teachCount,
      'learnCount': learnCount,
    });
  }

  static Future<SessionParticipant?> findActiveForUser(String userId) async {
    final userRef = docRef('users', userId);
    final snapshot = await FirestoreService.instance
        .collection('sessionParticipants')
        .where('participantId', isEqualTo: userRef)
        .where('isActive', isEqualTo: true)
        .get();
    if (snapshot.docs.isEmpty) {
      return null;
    }
    return SessionParticipant.fromSnapshot(snapshot.docs.first);
  }

  static Future<void> updateIsActive(String participantId, bool isActive) {
    return FirestoreService.instance
        .doc('/sessionParticipants/$participantId')
        .update({'isActive': isActive});
  }

  static Future<void> updateTeachAndLearnCounts(
      List<SessionParticipant> participants) async {
    if (participants.isEmpty) {
      return;
    }

    final WriteBatch batch = FirestoreService.instance.batch();
    for (var participant in participants) {
      batch.update(docRef('sessionParticipants', participant.id!), {
        'teachCount': participant.teachCount,
        'learnCount': participant.learnCount,
      });
    }

    await batch.commit();
  }
}

