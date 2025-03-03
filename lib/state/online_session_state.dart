import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/data_helpers/online_session_functions.dart';
import 'package:social_learning/data/online_session.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';

class OnlineSessionState extends ChangeNotifier {
  final ApplicationState applicationState;
  final LibraryState libraryState;

  OnlineSession? _waitingSession;
  OnlineSession? _activeSession;

  bool isInitialized = false;
  String? courseId = null;

  OnlineSession? get waitingSession => _waitingSession;

  OnlineSession? get activeSession => _activeSession;

  OnlineSessionState(this.applicationState, this.libraryState) {
    _attemptInit();

    applicationState.addListener(() {
      _attemptInit();
      if (applicationState.currentUser == null) {
        signOut();
      }
    });

    libraryState.addListener(() {
      String? newCourseId = libraryState.selectedCourse?.id;
      if (newCourseId != courseId) {
        courseId = newCourseId;

        // Cancel waiting session.
        if (_waitingSession != null) {
          OnlineSessionFunctions.cancelSession(_waitingSession!.id!);
        }

        _loadSessions();
      }
    });
  }

  void _attemptInit() {
    if (!isInitialized && (applicationState.currentUser != null)) {
      isInitialized = true;
      _loadSessions();

      notifyListeners();
    }
  }

  void _loadSessions() async {
    String? localCourseId = courseId;
    if (localCourseId == null) {
      _waitingSession = null;
      _activeSession = null;
      notifyListeners();
      return;
    }

    OnlineSession? session =
        await OnlineSessionFunctions.getWaitingOrActiveSession(
            applicationState.currentUser!.uid, localCourseId);

    if (session == null) {
      _waitingSession = null;
      _activeSession = null;
      notifyListeners();
      return;
    }

    // Verify state.
    if (session.status == OnlineSessionStatus.waiting) {
      // If the session is waiting and the heartbeat has expired, cancel it.
      if (session.lastActive!.toDate().isBefore(DateTime.now()
          .subtract(OnlineSessionFunctions.HEARTBEAT_EXPIRATION))) {
        await OnlineSessionFunctions.cancelSession(session.id!);
        _waitingSession = null;
        _activeSession = null;
        notifyListeners();
        return;
      }
    }

    // Determine the type of session it is.
    if (session.status == OnlineSessionStatus.waiting) {
      _waitingSession = session;
      _activeSession = null;
    } else if (session.status == OnlineSessionStatus.active) {
      _waitingSession = null;
      _activeSession = session;
    }

    notifyListeners();
  }

  /// Called when a session enters the waiting state.
  /// This sets the waitingSession and clears any activeSession.
  void setWaitingSession(OnlineSession? session) {
    _waitingSession = session;
    _activeSession = null;
    notifyListeners();
  }

  /// Called when a session becomes active.
  /// This sets the activeSession and clears any waitingSession.
  void setActiveSession(OnlineSession? session) {
    _activeSession = session;
    _waitingSession = null;
    notifyListeners();
  }

  void completeSession() {
    _waitingSession = null;
    _activeSession = null;
    notifyListeners();
  }

  /// Clears any stored session. Call this when a session ends.
  void signOut() {
    _waitingSession = null;
    _activeSession = null;
  }
}
