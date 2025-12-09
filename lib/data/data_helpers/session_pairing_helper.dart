import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:social_learning/data/data_helpers/reference_helper.dart';
import 'package:social_learning/data/firestore_service.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/session_pairing.dart';

class SessionPairingHelper {
  static Future<String> addPairing(SessionPairing pairing) async {
    var newDoc =
        await FirestoreService.instance.collection('sessionPairings').add({
      'sessionId': pairing.sessionId,
      'roundNumber': pairing.roundNumber,
      'mentorId': pairing.mentorId,
      'menteeId': pairing.menteeId,
      'lessonId': pairing.lessonId,
      'additionalStudentIds': pairing.additionalStudentIds,
    });
    print('Added session pairing ${newDoc.id}.');
    return newDoc.id;
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

  static Future<void> updateStudentsAndLesson(
      String pairingId,
      String? mentorUserId,
      String? menteeUserId,
      List<String>? additionalStudentUserIds,
      String? lessonId) async {
    DocumentReference? mentorRef =
        mentorUserId != null ? docRef('users', mentorUserId) : null;
    DocumentReference? menteeRef =
        menteeUserId != null ? docRef('users', menteeUserId) : null;
    List<DocumentReference> additionalStudentRefs =
        additionalStudentUserIds != null
            ? additionalStudentUserIds
                .map((userId) => docRef('users', userId))
                .whereType<DocumentReference>()
                .toList()
            : [];
    DocumentReference? lessonRef =
        lessonId != null ? docRef('lessons', lessonId) : null;

    try {
      await docRef('sessionPairings', pairingId).update({
        'mentorId': mentorRef,
        'menteeId': menteeRef,
        'lessonId': lessonRef,
        'additionalStudentIds': additionalStudentRefs,
      });
    } on FirebaseException catch (exception, stackTrace) {
      debugPrint('FirebaseException: ${exception.code} – ${exception.message}');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<void> removePairing(String pairingId) async {
    print('Delete session pairing $pairingId.');
    try {
      await docRef('sessionPairings', pairingId).delete();
    } on FirebaseException catch (exception, stackTrace) {
      print('Failed to remove session pairing $pairingId.');
      debugPrint('FirebaseException: ${exception.code} – ${exception.message}');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
    print('Removed session pairing $pairingId.');
  }
}
