import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/online_session.dart';
import 'package:social_learning/state/application_state.dart';

class OnlineSessionFunctions {
  // Constants for heartbeat and confirmation timings.
  static const Duration HEARTBEAT_INTERVAL = Duration(seconds: 60);
  static const Duration HEARTBEAT_EXPIRATION = Duration(minutes: 2);
  static const Duration CONFIRMATION_TIMEOUT = Duration(minutes: 5);

  static CollectionReference<Map<String, dynamic>>
      get _onlineSessionsCollection =>
          FirebaseFirestore.instance.collection('onlineSessions');

  /// Creates a new OnlineSession document in Firestore.
  /// The 'created' and 'lastActive' fields use the server timestamp.
  static Future<DocumentReference> createOnlineSession(
      OnlineSession session) async {
    Map<String, dynamic> sessionData = {
      'learnerUid': session.learnerUid,
      'mentorUid': session.mentorUid,
      'videoCallUrl': session.videoCallUrl,
      'isMentorInitiated': session.isMentorInitiated,
      // Save the status as an integer code.
      'status': session.status.code,
      'created': FieldValue.serverTimestamp(),
      'lastActive': FieldValue.serverTimestamp(),
      'pairedAt': session.pairedAt, // May be null until paired.
      'lessonId': session.lessonId,
    };

    print('Creating online session with data: $sessionData');

    return await _onlineSessionsCollection.add(sessionData);
  }

  /// Listens to sessions awaiting a mentor.
  /// These sessions are initiated by a learner (isMentorInitiated == false)
  /// and are waiting to be paired with a mentor.
  static Stream<List<OnlineSession>> listenSessionsAwaitingMentor(
      BuildContext context) {
    ApplicationState applicationState =
        Provider.of<ApplicationState>(context, listen: false);
    String? currentUserUid = applicationState.currentUser?.uid;

    DateTime validSince = DateTime.now().subtract(HEARTBEAT_EXPIRATION);
    Timestamp validSinceTimestamp = Timestamp.fromDate(validSince);

    print('Check validSinceTimestamp: $validSinceTimestamp');

    Query<Map<String, dynamic>> query = _onlineSessionsCollection
        .where('status', isEqualTo: OnlineSessionStatus.waiting.code)
        .where('lastActive', isGreaterThan: validSinceTimestamp)
        .where('isMentorInitiated', isEqualTo: false)
        .orderBy('lastActive');

    if (currentUserUid != null) {
      query = query.where('learnerUid', isNotEqualTo: currentUserUid);
      // query = query.where('mentorUid', isEqualTo: currentUserUid);
    }

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => OnlineSession.fromSnapshot(doc)).toList());
  }

  /// Listens to sessions awaiting a learner.
  /// These sessions are initiated by a mentor (isMentorInitiated == true)
  /// and are waiting to be paired with a learner.
  static Stream<List<OnlineSession>> listenSessionsAwaitingLearner(
      BuildContext context) {
    ApplicationState applicationState =
        Provider.of<ApplicationState>(context, listen: false);
    String? currentUserUid = applicationState.currentUser?.uid;

    DateTime validSince = DateTime.now().subtract(HEARTBEAT_EXPIRATION);
    Timestamp validSinceTimestamp = Timestamp.fromDate(validSince);

    Query<Map<String, dynamic>> query = _onlineSessionsCollection
        .where('status', isEqualTo: OnlineSessionStatus.waiting.code)
        .where('lastActive', isGreaterThan: validSinceTimestamp)
        .where('isMentorInitiated', isEqualTo: true);

    if (currentUserUid != null) {
      query = query.where('mentorUid', isNotEqualTo: currentUserUid);
    }

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => OnlineSession.fromSnapshot(doc)).toList());
  }

  /// Updates the heartbeat for the session document with the given [sessionId].
  /// This should be called periodically (e.g. every [HEARTBEAT_INTERVAL]).
  static Future<void> updateHeartbeat(String sessionId) async {
    await _onlineSessionsCollection.doc(sessionId).update({
      'lastActive': FieldValue.serverTimestamp(),
    });
  }

  /// Updates the session document when a second user has successfully been matched.
  /// Sets the [mentorId], [videoCallUrl], updates the status to 'active',
  /// and records the pairing time.
  static Future<void> updateSessionWithMatch({
    required String sessionId,
    String? learnerUid,
    String? mentorUid,
    required DocumentReference lessonRef,
  }) async {
    // Ensure that only learnerUid or mentorUid is set.
    assert((learnerUid != null && mentorUid == null) ||
        (learnerUid == null && mentorUid != null));

    var data = {
      'lessonId': lessonRef,
      'status': OnlineSessionStatus.active.code,
      'pairedAt': FieldValue.serverTimestamp(),
      'lastActive': FieldValue.serverTimestamp(),
    };

    if (learnerUid != null) {
      data['learnerUid'] = learnerUid;
    } else if (mentorUid != null) {
      data['mentorUid'] = mentorUid;
    } else {
      throw Exception('Either learnerUid or mentorUid must be provided.');
    }

    await _onlineSessionsCollection.doc(sessionId).update(data);
  }

  /// Cancels a session by updating its status to 'cancelled'.
  static Future<void> cancelSession(String sessionId) async {
    await _onlineSessionsCollection.doc(sessionId).update({
      'status': OnlineSessionStatus.cancelled.code,
      'lastActive': FieldValue.serverTimestamp(),
    });
  }

  static getWaitingOrActiveSession(String uid) async {
    // Build the base query filtering for waiting or active sessions.
    Query baseQuery = _onlineSessionsCollection.where('status', whereIn: [
      OnlineSessionStatus.waiting.code,
      OnlineSessionStatus.active.code,
    ]);

    // Query for sessions where the user is the learner.
    Query learnerQuery = baseQuery.where('learnerUid', isEqualTo: uid);
    // Query for sessions where the user is the mentor.
    Query mentorQuery = baseQuery.where('mentorUid', isEqualTo: uid);

    // Get both query snapshots.
    final results = await Future.wait([
      learnerQuery.get(),
      mentorQuery.get(),
    ]);

    QuerySnapshot learnerSnapshot = results[0];
    QuerySnapshot mentorSnapshot = results[1];

    // Convert snapshots to OnlineSession objects.
    List<OnlineSession> sessions = [];
    sessions.addAll(learnerSnapshot.docs.map((doc) =>
        OnlineSession.fromSnapshot(
            doc as DocumentSnapshot<Map<String, dynamic>>)));
    sessions.addAll(mentorSnapshot.docs.map((doc) => OnlineSession.fromSnapshot(
        doc as DocumentSnapshot<Map<String, dynamic>>)));

    if (sessions.isEmpty) return null;

    return sessions.first;
  }
}
