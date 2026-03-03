import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/session.dart';
import 'package:social_learning/session_pairing/party_pairing/party_pairing_algorithm.dart';
import 'package:social_learning/session_pairing/party_pairing/party_pairing_context.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/organizer_session_state.dart';

class InProcessPartyPairingService {
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

  void startService() {
    if (_isRunning) {
      return;
    }

    _isRunning = true;

    _organizerSessionState.addListener(_doIncrementalPairingGuard);

    _doIncrementalPairingGuard();
  }

  void stopService() {
    _organizerSessionState.removeListener(_doIncrementalPairingGuard);
    _isRunning = false;
  }

  void _doIncrementalPairingGuard() {
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
    Session? currentSession = _organizerSessionState.currentSession;
    if (currentSession == null || !currentSession.isActive) {
      return;
    }

    int? unitSize = _getUnitSize(currentSession);
    if (unitSize == null) {
      return;
    }

    PartyPairingContext pairingContext = PartyPairingContext(
      _applicationState,
      _libraryState,
      _organizerSessionState,
    );
    int unpairedCount = pairingContext.unpairedScoredParticipants.length;

    if (unpairedCount >= unitSize + 1) {
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
