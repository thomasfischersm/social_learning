import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/session.dart';
import 'package:social_learning/data/session_participant.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/ui_foundation/navigation_enum.dart';
import 'package:social_learning/data/user.dart';

class StudentSessionState extends ChangeNotifier {
  bool _isInitialized = false;
  get isInitialized => _isInitialized;

  Session? _currentSession;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _sessionsSubscription;

  get currentSession => _currentSession;

  List<SessionParticipant> _sessionParticipants = [];

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _sessionParticipantsSubscription;

  get sessionParticipants => _sessionParticipants;

  ApplicationState _applicationState;
  User? _lastUser;

  StudentSessionState(this._applicationState) {
    _applicationState.addListener(() {
      _checkForOngoingSession();
    });

    _checkForOngoingSession();
  }

  void _checkForOngoingSession() {
    print('StudentSessionState._checkForOngoingSession() for user ${_applicationState.currentUser?.id}');
    var lastUser = _applicationState.currentUser;
    if (lastUser == _lastUser) {
      // No change. Ignore!
      print('User hasn\'t changed.');
      return;
    }
    _lastUser = lastUser;

    if (lastUser == null) {
      // Clear any session.
      print('User is gone.');
      _resetSession();
      return;
    }

    print('Checking active session for user ${lastUser.id}');
    var userIdRef = FirebaseFirestore.instance.doc('/users/${lastUser.id}');
    FirebaseFirestore.instance
        .collection('sessionParticipants')
        .where('participantId', isEqualTo: userIdRef)
        .where('isActive', isEqualTo: true)
        .get()
        .then((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        var sessionParticipant =
            SessionParticipant.fromSnapshot(snapshot.docs.first);
        print('Trying to automatically log into session ${sessionParticipant.sessionId.id}');
        attemptToJoin(sessionParticipant.sessionId.id, null);
      }
    });
  }

  void attemptToJoin(String sessionId, BuildContext? context) {
    var oldSessionSubscription = _sessionsSubscription;
    if (oldSessionSubscription != null) {
      oldSessionSubscription.cancel();
      _sessionsSubscription = null;
    }

    _sessionsSubscription = FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .snapshots()
        .listen((snapshot) {
      print('Got new session for student: ${snapshot.data()}');
      _currentSession = Session.fromSnapshot(snapshot);
      _isInitialized = true;
      notifyListeners();

      // If the user is already the host, re-direct from the student to the
      // host page.
      if (_currentSession?.organizerUid == _applicationState.currentUser?.uid) {
        if (context != null) {
          Navigator.pushNamed(context, NavigationEnum.sessionHost.route);
        }
        return;
      }
    });

    var oldSessionParticipantsSubscription = _sessionParticipantsSubscription;
    if (oldSessionParticipantsSubscription != null) {
      oldSessionParticipantsSubscription.cancel();
      _sessionParticipantsSubscription = null;
    }

    String sessionPath = '/sessions/$sessionId';
    _sessionParticipantsSubscription = FirebaseFirestore.instance
        .collection('sessionParticipants')
        .where('sessionId',
            isEqualTo: FirebaseFirestore.instance.doc(sessionPath))
        .snapshots()
        .listen((snapshot) {
      print(
          'Got new session participants for student: ${snapshot.docs.length}');
      _sessionParticipants =
          snapshot.docs.map((e) => SessionParticipant.fromSnapshot(e)).toList();
      notifyListeners();

      // Check if self needs to be added.
      var containsSelf = _sessionParticipants.any((element) {
        print(
            'Checking if ${element.participantUid} == ${_applicationState.currentUser?.uid} => ${element.participantUid == _applicationState.currentUser?.uid}');
        return element.participantUid == _applicationState.currentUser?.uid;
      });
      print(
          'containsSelf: $containsSelf; this.uid: ${_applicationState.currentUser?.uid}');
      if (!containsSelf) {
        print('Student added itself as a participant');
        FirebaseFirestore.instance.collection('sessionParticipants').add({
          'sessionId': FirebaseFirestore.instance.doc(sessionPath),
          'participantId': FirebaseFirestore.instance
              .doc('/users/${_applicationState.currentUser?.id}'),
          'participantUid': _applicationState.currentUser?.uid,
          'isInstructor': false,
          'isActive': true,
        });
      }
    });

    // TODO: Check if organizer and re-direct.
    // TODO: Add self as participant if needed.
    // TODO: Subscribe to participants.
    // TODO: Figure out the bug why sessions aren't visible on the first try.
  }

  _resetSession() {
    _currentSession = null;
    _sessionParticipants = List.empty();
    _sessionsSubscription?.cancel();
    _sessionsSubscription = null;
    _sessionParticipantsSubscription?.cancel();
    _sessionParticipantsSubscription = null;

    notifyListeners();
  }
}
