import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/online_session.dart';

class OnlineSessionFunctions {
  // Constants for heartbeat and confirmation timings.
  static const Duration HEARTBEAT_INTERVAL = Duration(seconds: 60);
  static const Duration HEARTBEAT_EXPIRATION = Duration(minutes: 2);
  static const Duration CONFIRMATION_TIMEOUT = Duration(minutes: 5);

  static CollectionReference<Map<String, dynamic>> get _onlineSessionsCollection =>
      FirebaseFirestore.instance.collection('onlineSessions');

  /// Creates a new OnlineSession document in Firestore.
  /// The 'created' and 'lastActive' fields use the server timestamp.
  static Future<DocumentReference> createOnlineSession(OnlineSession session) async {
    Map<String, dynamic> sessionData = {
      'learnerId': session.learnerId,
      'mentorId': session.mentorId,
      'videoCallUrl': session.videoCallUrl,
      'isMentorInitiated': session.isMentorInitiated,
      // Save the status as an integer code.
      'status': session.status.code,
      'created': FieldValue.serverTimestamp(),
      'lastActive': FieldValue.serverTimestamp(),
      'pairedAt': session.pairedAt, // May be null until paired.
      'lessonId': session.lessonId,
    };

    return await _onlineSessionsCollection.add(sessionData);
  }

  /// Listens to sessions awaiting a mentor.
  /// These sessions are initiated by a learner (isMentorInitiated == false)
  /// and are waiting to be paired with a mentor.
  static Stream<List<OnlineSession>> listenSessionsAwaitingMentor() {
    DateTime validSince = DateTime.now().subtract(HEARTBEAT_EXPIRATION);
    Timestamp validSinceTimestamp = Timestamp.fromDate(validSince);

    return _onlineSessionsCollection
        .where('status', isEqualTo: OnlineSessionStatus.waiting.code)
        .where('lastActive', isGreaterThan: validSinceTimestamp)
        .where('isMentorInitiated', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => OnlineSession.fromSnapshot(doc))
        .toList());
  }

  /// Listens to sessions awaiting a learner.
  /// These sessions are initiated by a mentor (isMentorInitiated == true)
  /// and are waiting to be paired with a learner.
  static Stream<List<OnlineSession>> listenSessionsAwaitingLearner() {
    DateTime validSince = DateTime.now().subtract(HEARTBEAT_EXPIRATION);
    Timestamp validSinceTimestamp = Timestamp.fromDate(validSince);

    return _onlineSessionsCollection
        .where('status', isEqualTo: OnlineSessionStatus.waiting.code)
        .where('lastActive', isGreaterThan: validSinceTimestamp)
        .where('isMentorInitiated', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => OnlineSession.fromSnapshot(doc))
        .toList());
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
    required String mentorId,
    required String videoCallUrl,
  }) async {
    await _onlineSessionsCollection.doc(sessionId).update({
      'mentorId': mentorId,
      'videoCallUrl': videoCallUrl,
      'status': OnlineSessionStatus.active.code,
      'pairedAt': FieldValue.serverTimestamp(),
      'lastActive': FieldValue.serverTimestamp(),
    });
  }

  /// Cancels a session by updating its status to 'cancelled'.
  static Future<void> cancelSession(String sessionId) async {
    await _onlineSessionsCollection.doc(sessionId).update({
      'status': OnlineSessionStatus.cancelled.code,
      'lastActive': FieldValue.serverTimestamp(),
    });
  }
}