import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/session.dart';
import 'package:social_learning/data/session_participant.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/globals.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';

class OrganizerSessionState extends ChangeNotifier {
  Session? _currentSession;
  List<SessionParticipant> _sessionParticipants = List.empty();
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? sessionsSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      sessionParticipantsSubscription;

  createSession(String sessionName, ApplicationState applicationState,
      LibraryState libraryState) async {
    User? organizer = applicationState.currentUser;
    Course? course = libraryState.selectedCourse;

    if (organizer == null) {
      snackbarKey.currentState?.showSnackBar(const SnackBar(
        content:
            Text("Failed to create session because you are not logged in."),
      ));
      return;
    }

    if (course == null) {
      snackbarKey.currentState?.showSnackBar(const SnackBar(
        content:
            Text("Failed to create session because no course is selected."),
      ));
      return;
    }

    // Create session.
    DocumentReference<Map<String, dynamic>> sessionDoc = await FirebaseFirestore
        .instance
        .collection('sessions')
        .add(<String, dynamic>{
      'courseId': FirebaseFirestore.instance.doc('/courses/${course.id}'),
      'name': sessionName,
      'organizerUid': organizer.uid,
      'organizerName': organizer.displayName,
      'participantCount': 1,
      'startTime': null,
      'isActive': true,
    });
    String sessionId = sessionDoc.id;

    // Create organizer participant.
    print('before creating participant');
    DocumentReference<Map<String, dynamic>> participantDoc =
        await FirebaseFirestore.instance
            .collection('sessionParticipants')
            .add(<String, dynamic>{
      'sessionId': FirebaseFirestore.instance.doc('/sessions/$sessionId'),
      'participantId': FirebaseFirestore.instance.doc('/users/${organizer.id}'),
      'participantUid': organizer.uid,
      'isInstructor': organizer.isAdmin,
    });
    print('after creating participant');

    // Listen to session changes.
    sessionsSubscription = FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .snapshots()
        .listen((snapshot) {
      // if (event.size != 1) {
      //   print(
      //       'Id $sessionId returned an unexpected number of sessions: ${event.size}.');
      //   snackbarKey.currentState?.showSnackBar(SnackBar(
      //     content: Text(
      //         'Id $sessionId returned an unexpected number of sessions: ${event.size}.'),
      //   ));
      // }
      //
      // if (event.size > 1) {
      print('got session update ${snapshot.data()}');
      print('got session meta ${snapshot.metadata.hasPendingWrites}');
      if (!snapshot.metadata.hasPendingWrites) {
        // TODO: Handle updates from partial snapshot data.
        _currentSession = Session.fromSnapshot(snapshot);
        notifyListeners();
        print('got session update');
      }
    });

    // Listen to participant changes.
    sessionParticipantsSubscription = FirebaseFirestore.instance
        .collection('sessionParticipants')
        .where('sessionId', isEqualTo: FirebaseFirestore.instance.doc('/sessions/$sessionId'))
        .snapshots()
        .listen((snapshot) {
      _sessionParticipants =
          snapshot.docs.map((e) => SessionParticipant.fromSnapshot(e)).toList();

      if ((_currentSession != null) &&
          (_sessionParticipants.length != _currentSession?.participantCount)) {
        // Update the session participant count.
        FirebaseFirestore.instance
            .collection('sessions')
            .doc(sessionId)
            .set({'participantCount': _sessionParticipants.length});
      }

      notifyListeners();
    });

    notifyListeners();

    snackbarKey.currentState?.showSnackBar(SnackBar(
      content: Text('Successfully created session $sessionId'),
    ));
  }
}
