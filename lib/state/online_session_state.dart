import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/data_helpers/online_session_functions.dart';
import 'package:social_learning/data/data_helpers/online_session_review_functions.dart';
import 'package:social_learning/data/online_session.dart';
import 'package:social_learning/data/online_session_review.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';

class OnlineSessionState extends ChangeNotifier {
  final ApplicationState applicationState;
  final LibraryState libraryState;

  OnlineSession? _waitingSession;
  OnlineSession? _activeSession;
  OnlineSessionReview? _pendingReview;

  bool isInitialized = false;
  String? _courseId = null;

  OnlineSession? get waitingSession => _waitingSession;

  OnlineSession? get activeSession => _activeSession;

  OnlineSessionReview? get pendingReview => _pendingReview;

  OnlineSessionState(this.applicationState, this.libraryState) {
    _attemptInit();

    applicationState.addListener(() {
      print('OnlineSessionState received applicationState change');
      _attemptInit();
      if (applicationState.currentUser == null) {
        signOut();
      }
    });

    libraryState.addListener(() {
      print('OnlineSessionState received libraryState change');
      String? newCourseId = libraryState.selectedCourse?.id;
      if (newCourseId != _courseId) {
        _courseId = newCourseId;

        // Cancel waiting session.
        if (_waitingSession != null) {
          OnlineSessionFunctions.cancelSession(_waitingSession!.id!);
        }

        _loadSessions();
        _loadPendingReview();
      }
    });
  }

  void _attemptInit() {
    print('OnlineSessionState._attemptInit: isInitialized: $isInitialized, currentUser: ${applicationState.currentUser}');
    if (!isInitialized && (applicationState.currentUser != null)) {
      isInitialized = true;

      _courseId = libraryState.selectedCourse?.id;

      _loadSessions();
      _loadPendingReview();

      notifyListeners();
    }
  }

  void _loadSessions() async {
    String? localCourseId = _courseId;
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

  Future<void> _loadPendingReview() async {
    String? localCourseId = _courseId;
    if (localCourseId == null) {
      print('OnlineSessionState._loadPendingReview: No course selected.');
      _pendingReview = null;
      notifyListeners();
      return;
    }

    print('Attempt to load pending review for course $localCourseId');
    String currentUserUid = applicationState.currentUser!.uid;
    _pendingReview = await OnlineSessionFunctions.getPendingReview(
        currentUserUid, localCourseId);
    notifyListeners();
    print('Succeeded to load pending review for course $localCourseId, review: $pendingReview');
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

  Future<void> completeSession() async {
    _waitingSession = null;
    _activeSession = null;

    await _loadPendingReview();

    notifyListeners();
  }

  void completeReview() {
    _pendingReview = null;
    notifyListeners();
  }

  /// Clears any stored session. Call this when a session ends.
  void signOut() {
    _waitingSession = null;
    _activeSession = null;
  }
}
