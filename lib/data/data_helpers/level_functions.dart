import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:social_learning/data/Level.dart';
import 'package:social_learning/data/firestore_service.dart';

class LevelFunctions {
  static StreamSubscription<List<Level>> listenLevels(
      String courseId, void Function(List<Level>) onData) {
    final coursePath = '/courses/$courseId';
    return FirestoreService.instance
        .collection('levels')
        .where('courseId',
            isEqualTo: FirestoreService.instance.doc(coursePath))
        .orderBy('sortOrder', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((e) => Level.fromQuerySnapshot(e)).toList())
        .listen(onData);
  }

  static Future<void> setSortOrder(String levelId, int newSortOrder) {
    return FirestoreService.instance.doc('/levels/$levelId').set({
      'sortOrder': newSortOrder,
      'creatorId': auth.FirebaseAuth.instance.currentUser!.uid,
    }, SetOptions(merge: true));
  }

  static Future<void> updateLevel(String levelId, Map<String, dynamic> data) {
    return FirestoreService.instance
        .doc('/levels/$levelId')
        .set(data, SetOptions(merge: true));
  }

  static Future<void> deleteLevel(String levelId) {
    return FirestoreService.instance.doc('/levels/$levelId').delete();
  }

  static Future<DocumentReference<Map<String, dynamic>>> addLevel({
    required String courseId,
    required String title,
    required String description,
    required int sortOrder,
    required String creatorId,
  }) {
    return FirestoreService.instance.collection('levels').add({
      'courseId': FirestoreService.instance.doc('/courses/$courseId'),
      'title': title,
      'description': description,
      'sortOrder': sortOrder,
      'creatorId': creatorId,
    });
  }
}

