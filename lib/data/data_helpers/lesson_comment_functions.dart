import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:social_learning/data/data_helpers/reference_helper.dart';
import 'package:social_learning/data/firestore_service.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/lesson_comment.dart';
import 'package:social_learning/data/user.dart';

class LessonCommentFunctions {
  static final FirebaseFirestore _firestore = FirestoreService.instance;

  static Future<void> addLessonComment(
      Lesson lesson, String comment, User user) async {
    final userRef = docRef('users', user.id);
    final lessonRef = docRef('lessons', lesson.id!);

    await _firestore.collection('lessonComments').add({
      'lessonId': lessonRef,
      'text': comment,
      'creatorId': userRef,
      'creatorUid': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    print('finished firebase call to create comment');
  }

  static Future<void> deleteLessonComment(LessonComment comment) async {
    print('Deleting comment: ${comment.id}');
    await _firestore
        .doc('/lessonComments/${comment.id}')
        .delete()
        .onError((error, stackTrace) {
      print('Failed to delete comment: $error');
      debugPrintStack(stackTrace: stackTrace);
    });
  }
}1
