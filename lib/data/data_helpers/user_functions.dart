import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/student_state.dart';

class UserFunctions {
  static void createUser(String uid, String? displayName, String? email) {
    FirebaseFirestore.instance.collection('users').add(<String, dynamic>{
      'uid': auth.FirebaseAuth.instance.currentUser!.uid,
      'displayName': displayName,
      'sortName': displayName?.toLowerCase(),
      'email': email,
      'isProfilePrivate': false,
    });
  }

  static void updateDisplayName(String uid, String displayName) async {
    var querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('uid', isEqualTo: uid)
        .get();
    FirebaseFirestore.instance
        .collection('users')
        .doc(querySnapshot.docs[0].id)
        .update({
      'uid': auth.FirebaseAuth.instance.currentUser!.uid,
      'displayName': displayName,
      'sortName': displayName.toLowerCase(),
    });
  }

  static void updateProfilePhoto(String profileFireStoragePath) async {
    String uid = auth.FirebaseAuth.instance.currentUser!.uid;
    var querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('uid', isEqualTo: uid)
        .get();
    FirebaseFirestore.instance
        .collection('users')
        .doc(querySnapshot.docs[0].id)
        .update({
      'uid': auth.FirebaseAuth.instance.currentUser!.uid,
      'profileFireStoragePath': profileFireStoragePath,
    });
  }

  static void updateCurrentCourse(User currentUser, String courseId) async {
    var courseRef = FirebaseFirestore.instance.doc('/courses/$courseId');
    currentUser.currentCourseId = courseRef;
    FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.id)
        .set({'currentCourseId': courseRef}, SetOptions(merge: true));
  }

  static Future<List<User>> findUsersByPartialDisplayName(
      String partialDisplayName, int resultLimit) async {
    // Protect against charges.
    if (partialDisplayName.length < 3) {
      return [];
    }

    partialDisplayName = partialDisplayName.toLowerCase();
    String minStr = partialDisplayName;
    String maxStr = partialDisplayName.substring(
            0, partialDisplayName.length - 1) +
        String.fromCharCode(
            partialDisplayName.codeUnits[partialDisplayName.length - 1] + 1);

    var snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('sortName', isGreaterThanOrEqualTo: minStr)
        .where('sortName', isLessThan: maxStr)
        .limit(resultLimit)
        .get();
    List<User> users = snapshot.docs.map((e) => User.fromSnapshot(e)).toList();
    users.removeWhere(
        (user) => user.uid == auth.FirebaseAuth.instance.currentUser!.uid);

    return users;
  }

  static Future<User> getCurrentUser() async {
    String uid = auth.FirebaseAuth.instance.currentUser!.uid;
    var snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('uid', isEqualTo: uid)
        .get();
    var userDoc = snapshot.docs[0];
    return User.fromSnapshot(userDoc);
  }

  static String? extractNumberId(DocumentReference? id) {
    if (id != null) {
      var idStr = id.path;
      int index = idStr.lastIndexOf('/');
      if (index != -1) {
        return idStr.substring(index + 1);
      }
    }

    return null;
  }

  static void updateCourseProficiency(ApplicationState applicationState,
      LibraryState libraryState, StudentState studentState) async {
    // Calculate proficiency.
    Course? course = libraryState.selectedCourse;
    if (course == null) {
      return;
    }
    int lessons = max(libraryState.lessons?.length ?? 1, 1);
    int completedLessons = studentState.getLessonsLearned(course, libraryState);
    double proficiency = completedLessons / lessons.toDouble();
    proficiency = double.parse((proficiency.toStringAsFixed(2)));
    if (lessons == 1 || completedLessons == 0) {
      print(
          'Not updating proficiency because learned lessons or lesson count has not been loaded.');
      return;
    }

    // Check if the proficiency has changed.
    User? user = applicationState.currentUser;
    if (user == null) {
      return;
    }
    CourseProficiency? courseProficiency = user.getCourseProficiency(course);
    if (courseProficiency != null &&
        ((courseProficiency.proficiency - proficiency).abs() < 0.01)) {
      print(
          'Proficiency has not changed $proficiency. Completed lessons: $completedLessons, total lessons: $lessons.');
      return;
    }

    // Update course proficiency.
    if (courseProficiency != null) {
      // Remove the old entry.
      await FirebaseFirestore.instance.doc('/users/${user.id}').update({
        'courseProficiencies': FieldValue.arrayRemove([
          {
            'courseId': courseProficiency.courseId,
            'proficiency': courseProficiency.proficiency,
          }
        ]),
      });
    }

    // Add the new entry.
    await FirebaseFirestore.instance.doc('/users/${user.id}').update({
      'courseProficiencies': FieldValue.arrayUnion([
        {
          'courseId': FirebaseFirestore.instance.doc('/courses/${course.id}'),
          'proficiency': proficiency,
        }
      ]),
    });

    // Update the local value.
    if (courseProficiency != null) {
      courseProficiency.proficiency = proficiency;
    } else {
      user.courseProficiencies?.add(CourseProficiency(
          FirebaseFirestore.instance.doc('/courses/${course.id}'), proficiency));
    }

    print('Updated proficiency to $proficiency.');
  }
}
