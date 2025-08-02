import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:social_learning/data/firestore_service.dart';
import 'package:social_learning/data/lesson.dart';

class LessonFunctions {
  static StreamSubscription<List<Lesson>> listenLessons(
      String courseId, void Function(List<Lesson>) onData) {
    final coursePath = '/courses/$courseId';
    return FirestoreService.instance
        .collection('lessons')
        .where('courseId',
            isEqualTo: FirestoreService.instance.doc(coursePath))
        .orderBy('sortOrder', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((e) => Lesson.fromSnapshot(e)).toList())
        .listen(onData);
  }

  static Future<void> setSortOrder(String lessonId, int newSortOrder) {
    return FirestoreService.instance.doc('/lessons/$lessonId').set({
      'sortOrder': newSortOrder,
      'creatorId': auth.FirebaseAuth.instance.currentUser!.uid,
    }, SetOptions(merge: true));
  }

  static Future<void> deleteLesson(String lessonId) {
    return FirestoreService.instance.doc('/lessons/$lessonId').delete();
  }

  static Future<void> deleteCoverPhoto(String lessonId) async {
    final storageRef =
        FirebaseStorage.instance.ref('/lesson_covers/$lessonId/coverPhoto');
    await storageRef.delete();
  }

  static Future<DocumentReference<Map<String, dynamic>>> createLesson({
    required String courseId,
    DocumentReference? levelId,
    required int sortOrder,
    required String title,
    String? synopsis,
    required String instructions,
    String? recapVideo,
    String? lessonVideo,
    String? practiceVideo,
    List<String>? graduationRequirements,
    required String creatorId,
  }) {
    return FirestoreService.instance.collection('lessons').add({
      'courseId': FirestoreService.instance.doc('/courses/$courseId'),
      'levelId': levelId,
      'sortOrder': sortOrder,
      'title': title,
      'synopsis': synopsis,
      'instructions': instructions,
      'recapVideo': recapVideo,
      'lessonVideo': lessonVideo,
      'practiceVideo': practiceVideo,
      'creatorId': creatorId,
      'graduationRequirements': graduationRequirements,
    });
  }

  static Future<void> updateLesson(String lessonId, Map<String, dynamic> data) {
    return FirestoreService.instance
        .doc('/lessons/$lessonId')
        .set(data, SetOptions(merge: true));
  }

  static Future<void> attachLessonToLevel(
      String lessonId, String levelId) async {
    await FirestoreService.instance.doc('/lessons/$lessonId').set({
      'levelId': FirestoreService.instance.doc('/levels/$levelId'),
    }, SetOptions(merge: true));
  }

  static Future<void> detachLesson(String lessonId) {
    return FirestoreService.instance.doc('/lessons/$lessonId').set({
      'levelId': null,
    }, SetOptions(merge: true));
  }

  @Deprecated('Left over from the first version of the CMS.')
  static Future<void> createLessonLegacy(
      String courseId, String title, String instructions, bool isLevel) {
    return FirestoreService.instance.collection('lessons').add({
      'courseId': FirestoreService.instance.doc('/courses/$courseId'),
      'sortOrder': 0,
      'title': title,
      'instructions': instructions,
      'creatorId': auth.FirebaseAuth.instance.currentUser!.uid,
      'isLevel': isLevel,
    }).then((_) => null);
  }

  @Deprecated('Left over from the first version of the CMS.')
  static Future<void> updateLessonLegacy(
      String lessonId, String title, String instructions, bool isLevel) {
    return FirestoreService.instance.doc('/lessons/$lessonId').set({
      'title': title,
      'instructions': instructions,
      'creatorId': auth.FirebaseAuth.instance.currentUser!.uid,
      'isLevel': isLevel,
    }, SetOptions(merge: true));
  }
}

