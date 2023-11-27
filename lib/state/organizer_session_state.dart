import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/session.dart';
import 'package:social_learning/data/session_participant.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/data/user_functions.dart';
import 'package:social_learning/globals.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';

class OrganizerSessionState extends ChangeNotifier {
  Session? _currentSession;
  List<SessionParticipant> _sessionParticipants = List.empty();
  List<User> _participantUsers = List.empty();

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _sessionsSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _sessionParticipantsSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _participantUsersSubscription;

  get currentSession => _currentSession;

  get sessionParticipants => _sessionParticipants;

  get participantUsers => _participantUsers;

  OrganizerSessionState(ApplicationState applicationState) {
    _connectToActiveSession(applicationState);

    applicationState.addListener(() {
      _connectToActiveSession(applicationState);
    });
  }

  _connectToActiveSession(ApplicationState applicationState) {
    var uid = applicationState.currentUser?.uid;

    if (uid != null) {
      FirebaseFirestore.instance
          .collection('sessions')
          .where('organizerUid', isEqualTo: uid)
          .where('isActive')
          .get()
          .then((snapshot) {
        if (snapshot.size > 0) {
          var session = Session.fromQuerySnapshot(snapshot.docs.first);
          String sessionId = session.id!;
          _currentSession = session;

          _subscribeToSession(sessionId);
          _subscribeToParticipants(sessionId);
          notifyListeners();
        }
      });
    }
  }

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
      'startTime': FieldValue.serverTimestamp(),
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
    _subscribeToSession(sessionId);

    // Listen to participant changes.
    _subscribeToParticipants(sessionId);

    notifyListeners();

    snackbarKey.currentState?.showSnackBar(SnackBar(
      content: Text('Successfully created session $sessionId'),
    ));
  }

  _reconnectParticipantUsersSubscription() {
    // Disconnect from the old subscription.
    var oldSubscription = _participantUsersSubscription;
    if (oldSubscription != null) {
      oldSubscription.cancel();
    }

    // Build a list of user ids.
    List<String> userIds = [];
    for (SessionParticipant participant in _sessionParticipants) {
      var participantId = participant.participantId;
      if (participantId != null) {
        var rawUserId = UserFunctions.extractNumberId(participantId);
        if (rawUserId != null) {
          userIds.add(rawUserId);
        }
      }
    }

    // Subscribe to Firebase changes.
    print('_reconnectParticipantUsersSubscription: $userIds');
    if (userIds.isNotEmpty) {
      _participantUsersSubscription = FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: userIds)
          .snapshots()
          .listen((snapshot) {
        print('Received firebase update for session users: ${snapshot.size}');
        _participantUsers =
            snapshot.docs.map((e) => User.fromSnapshot(e)).toList();

        notifyListeners();
      });
    } else {
      _participantUsers = List.empty();
      notifyListeners();
    }
  }

  User? getParticipantUser(SessionParticipant sessionParticipant) {
    String? rawUserId =
        UserFunctions.extractNumberId(sessionParticipant.participantId);

    if (rawUserId != null) {
      for (User participantUser in _participantUsers) {
        if (participantUser.id == rawUserId) {
          return participantUser;
        }
      }
    }

    return null;
  }

  _subscribeToSession(String sessionId) {
    var oldSubscription = _sessionsSubscription;
    if (oldSubscription != null) {
      oldSubscription.cancel();
      _sessionsSubscription = null;
    }

    _sessionsSubscription = FirebaseFirestore.instance
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
  }

  _subscribeToParticipants(String sessionId) {
    var oldSubscription = _sessionParticipantsSubscription;
    if (oldSubscription != null) {
      oldSubscription.cancel();
      _sessionParticipantsSubscription = null;
    }

    print('Connecting host to listen to session participants.');
    _sessionParticipantsSubscription = FirebaseFirestore.instance
        .collection('sessionParticipants')
        .where('sessionId',
            isEqualTo: FirebaseFirestore.instance.doc('/sessions/$sessionId'))
        .snapshots()
        .listen((snapshot) {
      print('Got new session participants for host: ${snapshot.docs.length}');
      _sessionParticipants =
          snapshot.docs.map((e) => SessionParticipant.fromSnapshot(e)).toList();

      if ((_currentSession != null) &&
          (_sessionParticipants.length != _currentSession?.participantCount)) {
        // Update the session participant count.
        FirebaseFirestore.instance
            .collection('sessions')
            .doc(sessionId)
            .set({'participantCount': _sessionParticipants.length}, SetOptions(merge: true));
      }

      _reconnectParticipantUsersSubscription();

      notifyListeners();
    });
  }
}
