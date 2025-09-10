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
import 'package:social_learning/data/data_helpers/session_participant_functions.dart';

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
    _sessionSubscription = SessionSubscription(() {
      // Unsubscribe if the session ended.
      if (_sessionSubscription.item?.isActive == false) {
        _resetSession();
      }
      print(
          'StudentSessionState.notifyListeners because the session subscription changed');
      notifyListeners();
    });
    _participantUsersSubscription =
        ParticipantUsersSubscription(() => notifyListeners(), null);
    _sessionParticipantsSubscription =
        SessionParticipantsSubscription(false, true, () {
      print(
          'StudentSessionState.notifyListeners because session participants subscription changed');
      notifyListeners();
    }, _sessionSubscription, _participantUsersSubscription, _applicationState);
    _sessionPairingSubscription = SessionPairingsSubscription(() {
      print(
          'StudentSessionState.notifyListeners because session pairing subscription changed');
      notifyListeners();
    });

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

  User? getUserById(String? id) =>
      (id == null) ? null : _participantUsersSubscription.getUserById(id);

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
    SessionParticipantFunctions.findActiveForUser(currentUser.id)
        .then((sessionParticipant) {
      if (sessionParticipant != null) {
        print(
            'Trying to automatically log into session ${sessionParticipant.sessionId.id}');
        if (sessionParticipant.courseId.id == currentCourse?.id) {
          attemptToJoin(sessionParticipant.sessionId.id);
        } else {
          _resetSession();
        }
      }
    }).catchError((error) {
      print(
          'Error getting active participants for the current session: $error');
      _resetSession();
    });
  }

  void attemptToJoin(String sessionId) {
    _sessionSubscription.resubscribe(() => '/sessions/$sessionId');

    _sessionParticipantsSubscription.resubscribe((collectionReference) =>
        SessionParticipantFunctions.queryBySessionId(
            collectionReference, sessionId));

    _sessionPairingSubscription.resubscribe((collectionReference) =>
        collectionReference.where('sessionId',
            isEqualTo: FirebaseFirestore.instance.doc('/sessions/$sessionId')));

    // TODO: Check if organizer and re-direct.
    // TODO: Add self as participant if needed.
    // TODO: Subscribe to participants.
    // TODO: Figure out the bug why sessions aren't visible on the first try.
  }

  Future<void> leaveSession() async {
    final currentUser = _applicationState.currentUser;
    if (currentUser != null) {
      try {
        SessionParticipant? participant;
        try {
          participant = sessionParticipants
              .firstWhere((p) => p.participantId.id == currentUser.id);
        } catch (_) {
          participant = null;
        }
        if (participant != null && participant.id != null) {
          await _resetSession();
          await SessionParticipantFunctions.updateIsActive(
              participant.id!, false);
        }
      } catch (e) {
        debugPrint('Error leaving session: $e');
      }
    }
    _resetSession();
  }

  _resetSession() async {
    await signOut();

    print('StudentSessionState.notifyListeners because the session was reset');
    notifyListeners();
  }

  signOut() async {
    await _sessionSubscription.cancel();
    await _sessionParticipantsSubscription.cancel();
    await _participantUsersSubscription.cancel();
    await _sessionPairingSubscription.cancel();
  }
}
