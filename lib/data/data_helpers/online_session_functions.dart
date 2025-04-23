import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/data_helpers/practice_record_functions.dart';
import 'package:social_learning/data/data_helpers/reference_helper.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/online_session.dart';
import 'package:social_learning/data/online_session_review.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/online_session_state.dart';
import 'package:social_learning/state/student_state.dart';

enum WaitingRole {
  waitingForLearner, // Waiting for a learner (sessions initiated by a mentor)
  waitingForMentor, // Waiting for a mentor (sessions initiated by a learner)
}

class OnlineSessionFunctions {
  // Constants for heartbeat and confirmation timings.
  static const Duration HEARTBEAT_INTERVAL = Duration(seconds: 60);
  static const Duration HEARTBEAT_EXPIRATION = Duration(minutes: 2);
  static const Duration CONFIRMATION_TIMEOUT = Duration(minutes: 5);
  static const Duration CONFIRMATION_RESPONSE_TIMEOUT = Duration(minutes: 1);

  static CollectionReference<Map<String, dynamic>>
      get _onlineSessionsCollection =>
          FirebaseFirestore.instance.collection('onlineSessions');

  /// Creates a new OnlineSession document in Firestore.
  /// The 'created' and 'lastActive' fields use the server timestamp.
  static Future<DocumentReference> createOnlineSession(
      OnlineSession session) async {
    Map<String, dynamic> sessionData = {
      'courseId': session.courseId,
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

  static Future<OnlineSession> getOnlineSession(String sessionId) async {
    DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _onlineSessionsCollection.doc(sessionId).get();
    return OnlineSession.fromSnapshot(snapshot);
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> getSessionStream(
      String sessionId) {
    return _onlineSessionsCollection.doc(sessionId).snapshots();
  }

  /// Listens to sessions awaiting a mentor.
  /// These sessions are initiated by a learner (isMentorInitiated == false)
  /// and are waiting to be paired with a mentor.
  static Stream<List<OnlineSession>> listenSessionsAwaitingMentor(
      BuildContext context) {
    ApplicationState applicationState =
        Provider.of<ApplicationState>(context, listen: false);
    String? currentUserUid = applicationState.currentUser?.uid;

    LibraryState libraryState =
        Provider.of<LibraryState>(context, listen: false);
    String? courseId = libraryState.selectedCourse?.id;

    DateTime validSince = DateTime.now().subtract(HEARTBEAT_EXPIRATION);
    Timestamp validSinceTimestamp = Timestamp.fromDate(validSince);

    print('Check validSinceTimestamp: $validSinceTimestamp');

    Query<Map<String, dynamic>> query = _onlineSessionsCollection
        .where('courseId', isEqualTo: docRef('courses', courseId!))
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

    LibraryState libraryState =
        Provider.of<LibraryState>(context, listen: false);
    String? courseId = libraryState.selectedCourse?.id;

    DateTime validSince = DateTime.now().subtract(HEARTBEAT_EXPIRATION);
    Timestamp validSinceTimestamp = Timestamp.fromDate(validSince);

    Query<Map<String, dynamic>> query = _onlineSessionsCollection
        .where('courseId', isEqualTo: docRef('courses', courseId!))
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

  static Future<void> endSession(String sessionId) async {
    await _onlineSessionsCollection.doc(sessionId).update({
      'status': OnlineSessionStatus.completed.code,
      'lastActive': FieldValue.serverTimestamp(),
    });
  }

  static getWaitingOrActiveSession(String uid, String courseId) async {
    // Build the base query filtering for waiting or active sessions.
    Query baseQuery = _onlineSessionsCollection.where('status', whereIn: [
      OnlineSessionStatus.waiting.code,
      OnlineSessionStatus.active.code,
    ]).where('courseId', isEqualTo: docRef('courses', courseId));

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

  /// Tries to pair the current user with a waiting session.
  ///
  /// [waitingSessions]: The list of waiting sessions (already converted to OnlineSession).
  /// [waitingRole]: The current user's role:
  ///   - WaitingRole.learner: current user is a learner, so join a session initiated by a mentor.
  ///   - WaitingRole.mentor: current user is a mentor, so join a session initiated by a learner.
  /// [currentUserRef]: The Firestore DocumentReference for the current user.
  /// [canPartner]: A function that, given an OnlineSession, determines if the current user can
  ///    learn/teach from that session. It returns a DocumentReference for the lessonId if it’s a good match,
  ///    or null if not.
  ///
  /// Returns the updated OnlineSession if pairing was successful, or null if no suitable partner was found.
  static Future<OnlineSession?> tryPairWithWaitingSession(
      List<OnlineSession> waitingSessions,
      WaitingRole waitingRole,
      BuildContext context) async {
    DateTime now = DateTime.now();
    // Determine the cutoff time for an active session.
    DateTime validSince =
        now.subtract(OnlineSessionFunctions.HEARTBEAT_EXPIRATION);

    // Filter out sessions that are inactive (i.e. lastActive is too old).
    List<OnlineSession> activeSessions = waitingSessions.where((session) {
      if (session.lastActive == null) return false;
      DateTime lastActive = session.lastActive!.toDate();
      var isSessionActive = lastActive.isAfter(validSince) &&
          session.status == OnlineSessionStatus.waiting;
      print('Session ${session.id} is active: $isSessionActive');
      return isSessionActive;
    }).toList();

    // Filter sessions based on the current user's role.
    // For a learner (waitingRole.learner): we need sessions initiated by a mentor.
    // For a mentor (waitingRole.mentor): we need sessions initiated by a learner.
    activeSessions = activeSessions.where((session) {
      return waitingRole == WaitingRole.waitingForLearner
          ? !session.isMentorInitiated
          : session.isMentorInitiated;
    }).toList();

    // Sort the sessions by creation time (oldest first) so that the one on top of the queue is picked.
    activeSessions.sort((a, b) {
      DateTime aCreated = a.created?.toDate() ?? now;
      DateTime bCreated = b.created?.toDate() ?? now;
      return aCreated.compareTo(bCreated);
    });

    // Iterate over the eligible sessions.
    for (OnlineSession session in activeSessions) {
      print('Considering session: ${session.id}');
      // Ask the external method if the current user can partner on this session.
      DocumentReference? lessonRef = await canPartner(session, context);
      print('Found suggested lesson: $lessonRef');
      if (lessonRef != null) {
        // A good match is found. Build the update data.

        // Depending on the user's role, update the corresponding participant field.
        ApplicationState appState =
            Provider.of<ApplicationState>(context, listen: false);
        String currentUserUid = appState.currentUser!.uid;
        if (waitingRole == WaitingRole.waitingForLearner) {
          // Current user is a learner joining a session initiated by a mentor.
          if (!await pairWithTransaction(context, session.id!, lessonRef,
              mentorUid: currentUserUid)) {
            continue;
          }
        } else {
          // Current user is a mentor joining a session initiated by a learner.
          if (!await pairWithTransaction(context, session.id!, lessonRef,
              learnerUid: currentUserUid)) {
            continue;
          }
        }

        return session;
      }
      // If not a good match, proceed to the next session in the queue.
    }

    // No suitable partner was found.
    return null;
  }

  /// Tries to pair the current user with a waiting session.
  /// Returns false if another user has already paired with the session.
  static Future<bool> pairWithTransaction(
      BuildContext context, String sessionId, DocumentReference lessonRef,
      {String? learnerUid, String? mentorUid}) async {
    print('Pairing with session: $sessionId');
    if (learnerUid == null && mentorUid == null) {
      throw Exception('Either learnerUid or mentorUid must be provided.');
    }

    // Start transaction.
    bool success = false;
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      print('Start transaction to pair with session: $sessionId');
      var sessionRef = docRef('onlineSessions', sessionId);
      DocumentSnapshot<Map<String, dynamic>> snapshot =
          await transaction.get(sessionRef);
      if (!snapshot.exists) {
        print('Session does not exist.');
        return;
      }
      OnlineSession session = OnlineSession.fromSnapshot(snapshot);

      if (learnerUid != null && session.learnerUid != null) {
        print('Session already has a learner.');
        return;
      }

      if (mentorUid != null && session.mentorUid != null) {
        print('Session already has a mentor.');
        return;
      }

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

      transaction.update(sessionRef, data);
      success = true;
      print('Transaction completed for session: $sessionId');
    });

    print('Online session pair transaction result: $success');
    if (success) {
      OnlineSession session = await getOnlineSession(sessionId);
      OnlineSessionState onlineSessionState =
          Provider.of<OnlineSessionState>(context, listen: false);
      onlineSessionState.setActiveSession(session);
    }

    return success;
  }

  static Future<DocumentReference?> canPartner(
      OnlineSession session, BuildContext context) async {
    ApplicationState applicationState =
        Provider.of<ApplicationState>(context, listen: false);
    LibraryState libraryState =
        Provider.of<LibraryState>(context, listen: false);
    StudentState studentState =
        Provider.of<StudentState>(context, listen: false);

    // Get uids.
    // String thisStudentUid = applicationState.currentUser!.uid;
    String otherStudentUid =
        session.isMentorInitiated ? session.mentorUid! : session.learnerUid!;

    // Get lessons learned for the current user.
    List<String> thisStudentLessonIds = studentState.getGraduatedLessonIds();

    // Get learned lessons for the other user.
    List<String> otherStudentLessonIds =
        (await PracticeRecordFunctions.getLearnedLessonIds(otherStudentUid))
            .map((e) => e.id)
            .toList();

    // Find the first good lesson.
    Set<String> mentorLessonIds = (session.isMentorInitiated
            ? otherStudentLessonIds
            : thisStudentLessonIds)
        .toSet();
    Set<String> learnerLessonIds = (session.isMentorInitiated
            ? thisStudentLessonIds
            : otherStudentLessonIds)
        .toSet();
    print(
        'Trying pairing. Mentor lesson count: ${mentorLessonIds.length}. Learner lesson count: ${learnerLessonIds.length}');

    for (String lessonId in thisStudentLessonIds) {
      print('This student lesson: $lessonId');
    }

    List<Lesson>? lessons = libraryState.lessons;
    if (lessons != null) {
      for (Lesson lesson in lessons) {
        print(
            'Trying to partner lesson: ${lesson.id} ${lesson.title} mentor: ${mentorLessonIds.contains(lesson.id)} learner: ${learnerLessonIds.contains(lesson.id)}; this student: ${thisStudentLessonIds.contains(lesson.id)} other student: ${otherStudentLessonIds.contains(lesson.id)}');
        // TODO: Handle that admin can teach everything.
        if (mentorLessonIds.contains(lesson.id) &&
            !learnerLessonIds.contains(lesson.id)) {
          return docRef('lessons', lesson.id!);
        }
      }
    }

    return null;
  }

  static Future<OnlineSessionReview?> getPendingReview(
      String currentUserUid, String courseId) async {
    // try {
      QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('onlineSessionReviews')
          .where('courseId', isEqualTo: docRef('courses', courseId))
          .where('reviewerUid', isEqualTo: currentUserUid)
          .where('isPending', isEqualTo: true)
          .get();


    if (snapshot.docs.isEmpty) {
      return null;
    }

    return OnlineSessionReview.fromSnapshot(snapshot.docs.first);
    // } catch(e) {
    //   print('Error getting pending review: $e');
    //   rethrow;
    // }
  }
}
