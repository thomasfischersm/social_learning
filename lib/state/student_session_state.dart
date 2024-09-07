
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/session_participant.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/firestore_subscription/participant_users_subscription.dart';
import 'package:social_learning/state/firestore_subscription/session_pairings_subscription.dart';
import 'package:social_learning/state/firestore_subscription/session_participants_subscription.dart';
import 'package:social_learning/state/firestore_subscription/session_subscription.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/library_state.dart';

class StudentSessionState extends ChangeNotifier {
  get isInitialized => _sessionSubscription.isInitialized;

  late SessionSubscription _sessionSubscription;
  late SessionParticipantsSubscription _sessionParticipantsSubscription;
  late ParticipantUsersSubscription _participantUsersSubscription;
  late SessionPairingsSubscription _sessionPairingSubscription;

  get currentSession => _sessionSubscription.item;

  get sessionParticipants => _sessionParticipantsSubscription.items;

  final ApplicationState _applicationState;
  final LibraryState _libraryState;
  User? _lastUser;
  Course? _lastCourse;

  StudentSessionState(this._applicationState, this._libraryState) {
    _sessionSubscription = SessionSubscription(() => notifyListeners());
    _participantUsersSubscription =
        ParticipantUsersSubscription(() => notifyListeners(), null);
    _sessionParticipantsSubscription = SessionParticipantsSubscription(
        false,
        true,
        () => notifyListeners(),
        _sessionSubscription,
        _participantUsersSubscription,
        _applicationState);
    _sessionPairingSubscription =
        SessionPairingsSubscription(() => notifyListeners());

    _applicationState.addListener(() {
      _checkForOngoingSession();
    });

    _libraryState.addListener(() {
      _checkForOngoingSession();
    });

    _checkForOngoingSession();
  }

  get roundNumberToSessionPairing =>
      _sessionPairingSubscription.roundNumberToSessionPairings;

  User? getUserById(String id) => _participantUsersSubscription.getUserById(id);

  void _checkForOngoingSession() {
    print(
        'StudentSessionState._checkForOngoingSession() for user ${_applicationState.currentUser?.id}');

    var currentUser = _applicationState.currentUser;
    var currentCourse = _libraryState.selectedCourse;
    if ((currentUser == _lastUser) && (currentCourse == _lastCourse)) {
      // No change. Ignore!
      print('User and course haven\'t changed.');
      return;
    }
    _lastUser = currentUser;
    _lastCourse = currentCourse;

    if (currentUser == null) {
      // Clear any session.
      print('User is gone.');
      _resetSession();
      return;
    }

    print('Checking active session for user ${currentUser.id}');
    var userIdRef = FirebaseFirestore.instance.doc('/users/${currentUser.id}');
    FirebaseFirestore.instance
        .collection('sessionParticipants')
        .where('participantId', isEqualTo: userIdRef)
        .where('isActive', isEqualTo: true)
        .get()
        .then((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        var sessionParticipant =
            SessionParticipant.fromSnapshot(snapshot.docs.first);
        print(
            'Trying to automatically log into session ${sessionParticipant.sessionId.id}');
        if (sessionParticipant.courseId.id == currentCourse?.id) {
          attemptToJoin(sessionParticipant.sessionId.id);
        } else {
          _resetSession();
        }
      }
    });
  }

  void attemptToJoin(String sessionId) {
    _sessionSubscription.resubscribe(() => '/sessions/$sessionId');

    _sessionParticipantsSubscription.resubscribe((collectionReference) =>
        collectionReference.where('sessionId',
            isEqualTo: FirebaseFirestore.instance.doc('/sessions/$sessionId')));

    _sessionPairingSubscription.resubscribe((collectionReference) =>
        collectionReference.where('sessionId',
            isEqualTo: FirebaseFirestore.instance.doc('/sessions/$sessionId')));

    // TODO: Check if organizer and re-direct.
    // TODO: Add self as participant if needed.
    // TODO: Subscribe to participants.
    // TODO: Figure out the bug why sessions aren't visible on the first try.
  }

  _resetSession() {
    _sessionSubscription.cancel();
    _sessionParticipantsSubscription.cancel();
    _participantUsersSubscription.cancel();
    _sessionPairingSubscription.cancel();

    notifyListeners();
  }

  void signOut() {
    _sessionSubscription.cancel();
    _sessionParticipantsSubscription.cancel();
    _participantUsersSubscription.cancel();
    _sessionPairingSubscription.cancel();
  }
}
