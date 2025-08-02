import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/firestore_service.dart';

class LessonCommentFunctions {
  static Future<void> addComment({
    required String lessonId,
    required String userId,
    required String creatorUid,
    required String text,
  }) {
    final lessonRef = FirestoreService.instance.doc('/lessons/$lessonId');
    final userRef = FirestoreService.instance.doc('/users/$userId');
    return FirestoreService.instance.collection('lessonComments').add({
      'lessonId': lessonRef,
      'text': text,
      'creatorId': userRef,
      'creatorUid': creatorUid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteComment(String commentId) {
    return FirestoreService.instance.doc('/lessonComments/$commentId').delete();
  }
}

