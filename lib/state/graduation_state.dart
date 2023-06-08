
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social_learning/data/graduation.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

@Deprecated("Use StudentState")
class GraduationState extends ChangeNotifier {

  bool _isInitialized = false;
  List<Graduation>? _graduations;

  void _init() {
    if (!_isInitialized) {
      _isInitialized = true;

        FirebaseFirestore.instance
            .collection('graduations')
            .where('menteeUid', isEqualTo: auth.FirebaseAuth.instance.currentUser?.uid)
            .snapshots()
            .listen((snapshot) {
          _graduations =
              snapshot.docs.map((e) => Graduation.fromSnapshot(e)).toList();
          notifyListeners();
        });
    }
  }

  bool hasGraduated(Lesson? lesson) {
    if (lesson == null) {
      return false;
    }

    _init();
    return _graduations?.any((element) => element.lessonId == lesson.id) ?? false;
  }

  void graduate(Lesson lesson, User user) {
    var data = <String, dynamic>{
      'lessonId': lesson.id,
      'menteeUid': user.uid,
      'mentorUid': auth.FirebaseAuth.instance.currentUser?.uid,
      'timestamp': FieldValue.serverTimestamp(),
    };
    FirebaseFirestore.instance.collection('graduations').add(data);
    }
}
