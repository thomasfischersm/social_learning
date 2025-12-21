import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/data_helpers/session_pairing_helper.dart';
import 'package:social_learning/data/data_helpers/session_participant_functions.dart';
import 'package:social_learning/data/session.dart';
import 'package:social_learning/data/session_pairing.dart';
import 'package:social_learning/data/session_participant.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/firestore_subscription/participant_users_subscription.dart';
import 'package:social_learning/state/firestore_subscription/session_pairings_subscription.dart';
import 'package:social_learning/state/firestore_subscription/session_participants_subscription.dart';
import 'package:social_learning/state/firestore_subscription/session_subscription.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/advanced_pairing_student_page.dart';
import 'package:social_learning/ui_foundation/session_student_page.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';
import 'package:social_learning/util/list_util.dart';

class StudentSessionState extends ChangeNotifier {
  bool get isInitialized => _sessionSubscription.isInitialized;

  late SessionSubscription _sessionSubscription;
  late SessionParticipantsSubscription _sessionParticipantsSubscription;
  late ParticipantUsersSubscription _participantUsersSubscription;
  late SessionPairingsSubscription _sessionPairingSubscription;

  Session? get currentSession => _sessionSubscription.item;

  List<SessionParticipant> get sessionParticipants =>
      _sessionParticipantsSubscription.items;

  List<SessionPairing> get allPairings => _sessionPairingSubscription.items;

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

  Map<int, List<SessionPairing>> get roundNumberToSessionPairing =>
      _sessionPairingSubscription.roundNumberToSessionPairings;

  User? getUserById(String? id) =>
      (id == null) ? null : _participantUsersSubscription.getUserById(id);

  SessionPairing? get currentPairing {
    final currentUserId = _applicationState.currentUser?.id;
    final session = currentSession;

    if (currentUserId == null || session == null) {
      return null;
    }

    switch (session.sessionType) {
      case SessionType.automaticManual:
        return _findCurrentPairingForAutomaticSessions(currentUserId);
      case SessionType.powerMode:
      case SessionType.partyMode:
      default:
        return _findCurrentForAdvancedSessions(currentUserId);
    }
  }

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

    if (currentCourse == null) {
      print('Trying to check for ongoing session, but no course is selected!');
      return;
    }

    print('Checking active session for user ${currentUser.id}');
    SessionParticipantFunctions.findActiveForUser(currentUser.id, currentCourse.id!)
        .then((sessionParticipant) {
      if (sessionParticipant != null) {
        print(
            'Trying to automatically log into session '
                '${sessionParticipant.sessionId.id} '
                '(session: ${sessionParticipant.sessionId.id}), '
                'course: ${sessionParticipant.courseId.id}');
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
    _sessionSubscription.resubscribe(() => 'sessions/$sessionId');

    _sessionParticipantsSubscription.resubscribe((collectionReference) =>
        SessionParticipantFunctions.queryBySessionId(
            collectionReference, sessionId));

    _sessionPairingSubscription.resubscribe((collectionReference) =>
        collectionReference.where('sessionId',
            isEqualTo: FirebaseFirestore.instance.doc('sessions/$sessionId')));

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

  Future<void> _resetSession() async {
    await signOut();

    print('StudentSessionState.notifyListeners because the session was reset');
    notifyListeners();
  }

  Future<void> signOut() async {
    await _sessionSubscription.cancel();
    await _sessionParticipantsSubscription.cancel();
    await _participantUsersSubscription.cancel();
    await _sessionPairingSubscription.cancel();
  }

  Future<void> completeCurrentPairing() async {
    final pairing = currentPairing;
    if (pairing?.id != null) {
      await completePairing(pairing!.id!);
    }
  }

  Future<void> completePairing(String pairingId) async {
    await SessionPairingFunctions.completePairing(pairingId);
  }

  SessionPairing? _findCurrentPairingForAutomaticSessions(
      String currentUserId) {
    final currentRound = _sessionPairingSubscription.getLatestRoundNumber();
    if (currentRound < 0) {
      return null;
    }

    final roundPairings = roundNumberToSessionPairing[currentRound];
    if (roundPairings == null) {
      return null;
    }

    for (final pairing in roundPairings) {
      if (_pairingIncludesUser(pairing, currentUserId) &&
          !pairing.isCompleted) {
        return pairing;
      }
    }

    return null;
  }

  SessionPairing? _findCurrentForAdvancedSessions(String currentUserId) {
    List<SessionPairing> relevantPairings = allPairings
        .where((pairing) => _pairingIncludesUser(pairing, currentUserId))
        .toList();

    SessionPairing? lastPairing = relevantPairings
        .maxByOrNull((a, b) => b.roundNumber.compareTo(a.roundNumber));

    return lastPairing?.isCompleted ?? true ? null : lastPairing;
  }

  bool _pairingIncludesUser(SessionPairing pairing, String userId) {
    if ((pairing.mentorId?.id == userId) || (pairing.menteeId?.id == userId)) {
      return true;
    }

    return pairing.additionalStudentIds.any((ref) => ref.id == userId);
  }

  NavigationEnum getActiveSessionNavigationEnum(
      {Session? session, String? sessionId, SessionType? sessionType}) {
    Session? targetSession = session ?? currentSession;
    SessionType? targetSessionType = sessionType ?? targetSession?.sessionType;
    print('Active session ${targetSession?.id} has sessionType $targetSessionType');

    if (targetSessionType == null) {
      return NavigationEnum.sessionHome;
    }

    switch (targetSessionType) {
      case SessionType.automaticManual:
        return NavigationEnum.sessionStudent;
      case SessionType.powerMode:
        return NavigationEnum.advancedPairingStudent;
      case SessionType.partyMode:
        return NavigationEnum.advancedPairingStudent;
    }
  }

  void navigateToActiveSessionPage(BuildContext context,
      {Session? session, String? sessionId, SessionType? sessionType}) {
    Session? targetSession = session ?? currentSession;
    String? targetSessionId = sessionId ?? targetSession?.id;
    NavigationEnum? navigationEnum = getActiveSessionNavigationEnum(
      session: targetSession,
      sessionId: targetSessionId,
      sessionType: sessionType,
    );

    if ((navigationEnum == null) || (targetSessionId == null)) {
      return;
    }

    final Object arguments;
    switch (navigationEnum) {
      case NavigationEnum.sessionStudent:
        arguments = SessionStudentArgument(targetSessionId);
        break;
      case NavigationEnum.advancedPairingStudent:
        arguments = AdvancedPairingStudentArgument(targetSessionId);
        break;
      default:
        arguments = SessionStudentArgument(targetSessionId);
        break;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      navigationEnum.route,
      (route) => route.settings.name == NavigationEnum.home.route,
      arguments: arguments,
    );
  }
}
