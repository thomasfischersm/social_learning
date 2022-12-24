import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/course.dart';
import '../firebase_options.dart';

class ApplicationState extends ChangeNotifier {
  ApplicationState() {
    init();
  }

  String? get userDisplayName => auth.FirebaseAuth.instance.currentUser?.displayName;

  set userDisplayName(String? newDisplayName) {
    auth.FirebaseAuth.instance.currentUser?.updateDisplayName(newDisplayName);
    notifyListeners();
  }

  bool _loggedIn = false;

  bool get isLoggedIn => _loggedIn;

  bool get isCourseSelected => _selectedCourse != null;

  Course? _selectedCourse;

  Course? get selectedCourse => _selectedCourse;

  set selectedCourse(Course? course) {
    _selectedCourse = course;
    notifyListeners();
  }

  var _availableCourses = <Course>[];
  bool _isCourseListLoaded = false;

  List<Course> get availableCourses {
    if (!_isCourseListLoaded) {
      _isCourseListLoaded = true;
      loadCourseList();
    }
    return _availableCourses;
  }

  Future<void> init() async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    FirebaseUIAuth.configureProviders([
      EmailAuthProvider(),
    ]);

    auth.FirebaseAuth.instance.idTokenChanges().listen((auth.User? user) {
      if (user == null) {
        _loggedIn = false;
      } else {
        _loggedIn = true;
      }
      notifyListeners();
    });
  }

  Future<void> loadCourseList() async {
    // Create courses.
    // FirebaseFirestore.instance.collection('courses').add(<String, dynamic>{
    //   'title': 'Argentine Tango',
    //   'creatorId': auth.FirebaseAuth.instance.currentUser!.uid,
    // });

    FirebaseFirestore.instance
        .collection('courses')
        .orderBy('title', descending: false)
        .snapshots()
        .listen((snapshot) {
      _availableCourses =
          snapshot.docs.map((e) => Course.fromSnapshot(e)).toList();
      notifyListeners();
    });
  }
}
