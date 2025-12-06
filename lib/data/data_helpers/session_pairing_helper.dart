import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/data_helpers/reference_helper.dart';
import 'package:social_learning/data/firestore_service.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/session_pairing.dart';

class SessionPairingHelper {
  static Future<String> addPairing(SessionPairing pairing) async {
    return (await FirestoreService.instance.collection('sessionPairings').add({
      'sessionId': pairing.sessionId,
      'roundNumber': pairing.roundNumber,
      'mentorId': pairing.mentorId,
      'menteeId': pairing.menteeId,
      'lessonId': pairing.lessonId,
      'additionalStudentIds': pairing.additionalStudentIds,
    }))
        .id;
  }

  static void addLesson(SessionPairing sessionPairing, Lesson lesson) {
    docRef('sessionPairings', sessionPairing.id!).update({
      'lessonId': docRef('lessons', lesson.id!),
    }).then((value) {
      print('Added lesson to session pairing.');
    }).catchError((error) {
      print('Failed to add lesson to session pairing: $error');
    });
  }

  static void removeLesson(SessionPairing sessionPairing) {
    docRef('sessionPairings', sessionPairing.id!).update({
      'lessonId': null,
    }).then((value) {
      print('Removed lesson from session pairing.');
    }).catchError((error) {
      print('Failed to remove lesson from session pairing: $error');
    });
  }

  static void updateStudentsAndLesson(String pairingId,
      String? mentorUserId,
      String? menteeUserId,
      List<String>? additionalStudentUserIds,
      String? lessonId) {
    DocumentReference? mentorRef = mentorUserId != null ? docRef(
        'users', mentorUserId) : null;
    DocumentReference? menteeRef = menteeUserId != null ? docRef(
        'users', menteeUserId) : null;
    List<DocumentReference> additionalStudentRefs = additionalStudentUserIds !=
        null ? additionalStudentUserIds
        .map((userId) => docRef('users', userId))
        .whereType<DocumentReference>()
        .toList() : [];
    DocumentReference? lessonRef = lessonId != null ? docRef(
        'lessons', lessonId) : null;


    docRef('sessionPairings', pairingId).update({
      'mentorId': mentorRef,
      'menteeId': menteeRef,
      'lessonId': lessonRef,
      'additionalStudentIds': additionalStudentRefs,
        });
  }

  static void removePairing(String pairingId) {
    docRef('sessionPairings', pairingId).delete().then((value) {
      print('Removed session pairing $pairingId.');
    }).catchError((error) {
      print('Failed to remove session pairing $pairingId.');
    });
  }
}
