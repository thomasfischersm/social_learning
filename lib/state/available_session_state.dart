
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/session.dart';
import 'package:social_learning/state/library_state.dart';

class AvailableSessionState extends ChangeNotifier {

  Course? _lastCourse;
  StreamSubscription? _lastSubscription;
  List<Session> _availableSessions = [];

  List<Session> get availableSessions => _availableSessions;

  AvailableSessionState(LibraryState libraryState) {
    print('AvailableSessionState cstr()');
    libraryState.addListener(() { onLibraryStateUpdated(libraryState);});

    onLibraryStateUpdated(libraryState);
  }

  void onLibraryStateUpdated(LibraryState libraryState) {
    print('AvailableSessionState.onLibraryStateUpdated(); course: ${libraryState.selectedCourse?.title}');
    Course? newCourse = libraryState.selectedCourse;
    if (_lastCourse == newCourse) {
      // No change. Ignore!
      return;
    }

    _lastCourse = newCourse;
    _lastSubscription?.cancel();
    if (newCourse == null) {
      // Clear the data.
      _availableSessions = List.empty();
      notifyListeners();
      return;
    }

    // Load sessions.
    String coursePath = '/courses/${newCourse.id}';

    _lastSubscription = FirebaseFirestore.instance
        .collection('sessions')
        .where('courseId',
        isEqualTo: FirebaseFirestore.instance.doc(coursePath))
        .where('isActive', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      _availableSessions = snapshot.docs.map((e) => Session.fromQuerySnapshot(e)).toList();
      print('Loaded ${_availableSessions.length} available sessions.');
      notifyListeners();
    });
  }

  void signOut() {
    _lastSubscription?.cancel();
    _lastSubscription = null;
    _lastCourse = null;
    _availableSessions = List.empty();
  }
}