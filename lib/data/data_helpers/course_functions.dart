import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/firestore_service.dart';

class CourseFunctions {
  static StreamSubscription<List<Course>> listenPublicCourses(
      void Function(List<Course>) onData,
      {Function? onError}) {
    return FirestoreService.instance
        .collection('courses')
        .where('isPrivate', isEqualTo: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((e) => Course.fromSnapshot(e)).toList())
        .listen(onData, onError: onError);
  }

  static Future<List<Course>> fetchEnrolledPrivateCourses(
      List<String> enrolledCourseIds) async {
    if (enrolledCourseIds.isEmpty) {
      return [];
    }

    final snapshot = await FirestoreService.instance
        .collection('courses')
        .where(FieldPath.documentId, whereIn: enrolledCourseIds)
        .where('isPrivate', isEqualTo: true)
        .get();
    return snapshot.docs.map((e) => Course.fromSnapshot(e)).toList();
  }

  static Future<bool> titleExists(String title) async {
    final snapshot = await FirestoreService.instance
        .collection('courses')
        .where('title', isEqualTo: title)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  static Future<bool> invitationCodeExists(String invitationCode) async {
    final snapshot = await FirestoreService.instance
        .collection('courses')
        .where('invitationCode', isEqualTo: invitationCode)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  static Future<DocumentReference<Map<String, dynamic>>> createPrivateCourse(
      {required String title,
      required String description,
      required String invitationCode,
      required String creatorId,
      String? whatsappLink}) {
    return FirestoreService.instance.collection('courses').add({
      'title': title,
      'description': description,
      'creatorId': creatorId,
      'isPrivate': true,
      'invitationCode': invitationCode,
      'whatsappLink': whatsappLink,
    });
  }

  static Future<void> updateCourse(
      String courseId, Map<String, dynamic> data) {
    return FirestoreService.instance
        .doc('/courses/$courseId')
        .set(data, SetOptions(merge: true));
  }

  static Future<Course?> findCourseByInvitationCode(String code) async {
    final snapshot = await FirestoreService.instance
        .collection('courses')
        .where('invitationCode', isEqualTo: code)
        .get();
    if (snapshot.docs.isEmpty) {
      return null;
    }
    return Course.fromSnapshot(snapshot.docs.first);
  }
}

