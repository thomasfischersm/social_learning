import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/session.dart';
import 'package:social_learning/session_pairing/party_pairing/party_pairing_algorithm.dart';
import 'package:social_learning/session_pairing/party_pairing/party_pairing_context.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/organizer_session_state.dart';

class InProcessPartyPairingService extends ChangeNotifier {
  final ApplicationState _applicationState;
  final LibraryState _libraryState;
  final OrganizerSessionState _organizerSessionState;

  bool _isRunning = false;
  bool _isPairing = false;
  bool _hasPendingPairingRequest = false;

  InProcessPartyPairingService(
    this._applicationState,
    this._libraryState,
    this._organizerSessionState,
  );

  bool get isRunning => _isRunning;

  void startService() {
    if (_isRunning) {
      return;
    }

    _isRunning = true;

    _organizerSessionState.addListener(_doIncrementalPairingGuard);

    _doIncrementalPairingGuard();

    print('Started InProcessPartyPairingService.');
    notifyListeners();
  }

  void stopService() {
    _organizerSessionState.removeListener(_doIncrementalPairingGuard);
    _isRunning = false;

    print('Stopped InProcessPartyPairingService.');
    notifyListeners();
  }

  void _doIncrementalPairingGuard() {
    print(
      'Triggered incremental pairing. ('
      'isRunning: $_isRunning, '
      'isPairing: $_isPairing, '
      'hasPendingPairingRequest: $_hasPendingPairingRequest)',
    );

    if (!_isRunning) {
      return;
    }

    if (_isPairing) {
      _hasPendingPairingRequest = true;
      return;
    }

    _isPairing = true;

    _doIncrementalPairing();

    _isPairing = false;

    if (_hasPendingPairingRequest) {
      _hasPendingPairingRequest = false;
      _doIncrementalPairingGuard();
    }
  }

  void _doIncrementalPairing() {
    print('_doIncrementalPairing is called');
    Session? currentSession = _organizerSessionState.currentSession;
    if (currentSession == null || !currentSession.isActive) {
      print('The current session is not active.');
      return;
    }

    int? unitSize = _getUnitSize(currentSession);
    print('Got unit size: $unitSize');
    if (unitSize == null) {
      return;
    }

    PartyPairingContext pairingContext = PartyPairingContext(
      _applicationState,
      _libraryState,
      _organizerSessionState,
    );
    int unpairedCount = pairingContext.unpairedScoredParticipants.length;
    int activeParticipantCount = _organizerSessionState.sessionParticipants
        .where(
          (participant) {
            print('Participant: '
                'userId: ${participant.participantId.id}, '
                'active: ${participant.isActive}, '
                'instructor: ${participant.isInstructor}');
              return participant.isActive &&
              (!participant.isInstructor ||
                  currentSession.includeHostInPairing);}
        )
        .length;

    // Handle the special case where the session size is 3 and the
    // pairing size is 3. (And 2 respectively.)
    print('Copy of Building student roster with ${_organizerSessionState.sessionParticipants.length} participants. ${identityHashCode(_organizerSessionState)}');
    print('currentSession.includeHostInPairing = ${currentSession.includeHostInPairing}');
    print(
      'Considering starting the pairing algorithm: '
      'unitSize: $unitSize, '
      'allParticipantCount: ${_organizerSessionState.sessionParticipants.length}, '
      'allParticipantUsersCount: ${_organizerSessionState.participantUsers.length}, '
      'unpairedCount: $unpairedCount, '
      'activeParticipantCount: $activeParticipantCount',
    );
    if (unpairedCount >= unitSize + 1 || (activeParticipantCount == unitSize)) {
      print('Actually doing the incremental pairing');
      PartyPairingAlgorithm(
        unitSize,
      ).pairAvailableStudentsAndPersist(pairingContext);
    }
  }

  int? _getUnitSize(Session session) {
    switch (session.sessionType) {
      case SessionType.partyModeDuo:
        return 2;
      case SessionType.partyModeTrio:
        return 3;
      default:
        return null;
    }
  }
}
