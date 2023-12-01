import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/practice_record.dart';
import 'package:social_learning/data/session.dart';
import 'package:social_learning/data/session_pairing.dart';
import 'package:social_learning/data/session_participant.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/data/user_functions.dart';
import 'package:social_learning/data_support/firestore_document_subscription.dart';
import 'package:social_learning/data_support/firestore_list_subscription.dart';
import 'package:social_learning/globals.dart';
import 'package:social_learning/session_pairing/session_pairing_algorithm.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';

class OrganizerSessionState extends ChangeNotifier {
  bool _isInitialized = false;

  final LibraryState _libraryState;

  get isInitialized => _isInitialized;

  // new subscriptions
  late FirestoreDocumentSubscription _sessionsSubscription;

  late FirestoreListSubscription _sessionParticipantsSubscription;

  late FirestoreListSubscription _participantUsersSubscription;

  late FirestoreListSubscription _practiceRecordsSubscription;

  late FirestoreListSubscription _sessionPairingSubscription;

  get currentSession => _sessionsSubscription.item;

  get sessionParticipants => _sessionParticipantsSubscription.items;

  get participantUsers => _participantUsersSubscription.items;

  get practiceRecords => _practiceRecordsSubscription.items;

  Map<User, List<Lesson>> _userToGraduatedLessons = {};

  Map<String, User> _uidToUserMap = {};

  Map<int, List<SessionPairing>> _roundNumberToSessionPairings = {};

  OrganizerSessionState(ApplicationState applicationState, this._libraryState) {
    // Start subscriptions.
     _sessionsSubscription =
    FirestoreDocumentSubscription<Session>(
            (snapshot) => Session.fromSnapshot(snapshot), () {
      _isInitialized = true;
      notifyListeners();
    });

     _sessionParticipantsSubscription =
    FirestoreListSubscription<SessionParticipant>(
        'sessionParticipants',
            (snapshot) => SessionParticipant.fromSnapshot(snapshot),
        _handleSessionParticipantsUpdate,
            () => notifyListeners());

    _participantUsersSubscription =
    FirestoreListSubscription<User>(
        'users',
            (snapshot) => User.fromSnapshot(snapshot),
            (participantUsers) => _uidToUserMap = {
          for (var user in participantUsers) user.uid: user
        },
            () => notifyListeners());

    final FirestoreListSubscription _practiceRecordsSubscription =
    FirestoreListSubscription<PracticeRecord>(
      'practiceRecords',
          (snapshot) => PracticeRecord.fromSnapshot(snapshot),
          (practiceRecords) => _userToGraduatedLessons = {},
          () => notifyListeners(),
    );

    final FirestoreListSubscription _sessionPairingSubscription =
    FirestoreListSubscription<SessionPairing>(
      'sessionPairings',
          (snapshot) => SessionPairing.fromSnapshot(snapshot),
      null,
          () => notifyListeners(),
    );

    // Check if the user logged back into the app with a running session.
    _connectToActiveSession(applicationState);

    applicationState.addListener(() {
      _connectToActiveSession(applicationState);
    });
  }

  _connectToActiveSession(ApplicationState applicationState) {
    var uid = applicationState.currentUser?.uid;

    if (uid != null) {
      FirebaseFirestore.instance
          .collection('sessions')
          .where('organizerUid', isEqualTo: uid)
          .where('isActive')
          .get()
          .then((snapshot) {
        if (snapshot.size > 0) {
          var session = Session.fromQuerySnapshot(snapshot.docs.first);
          String sessionId = session.id!;
          // _currentSession = session;

          _subscribeToSession(sessionId);
          _isInitialized = true;
          notifyListeners();
        }
      });
    }
  }

  createSession(String sessionName, ApplicationState applicationState,
      LibraryState libraryState) async {
    User? organizer = applicationState.currentUser;
    Course? course = libraryState.selectedCourse;

    if (organizer == null) {
      snackbarKey.currentState?.showSnackBar(const SnackBar(
        content:
            Text("Failed to create session because you are not logged in."),
      ));
      return;
    }

    if (course == null) {
      snackbarKey.currentState?.showSnackBar(const SnackBar(
        content:
            Text("Failed to create session because no course is selected."),
      ));
      return;
    }

    // Create session.
    DocumentReference<Map<String, dynamic>> sessionDoc = await FirebaseFirestore
        .instance
        .collection('sessions')
        .add(<String, dynamic>{
      'courseId': FirebaseFirestore.instance.doc('/courses/${course.id}'),
      'name': sessionName,
      'organizerUid': organizer.uid,
      'organizerName': organizer.displayName,
      'participantCount': 1,
      'startTime': FieldValue.serverTimestamp(),
      'isActive': true,
    });
    String sessionId = sessionDoc.id;

    // Create organizer participant.
    print('before creating participant');
    DocumentReference<Map<String, dynamic>> participantDoc =
        await FirebaseFirestore.instance
            .collection('sessionParticipants')
            .add(<String, dynamic>{
      'sessionId': FirebaseFirestore.instance.doc('/sessions/$sessionId'),
      'participantId': FirebaseFirestore.instance.doc('/users/${organizer.id}'),
      'participantUid': organizer.uid,
      'isInstructor': organizer.isAdmin,
      'isActive': true,
    });
    print('after creating participant');

    // Listen to session changes.
    _subscribeToSession(sessionId);

    notifyListeners();

    snackbarKey.currentState?.showSnackBar(SnackBar(
      content: Text('Successfully created session $sessionId'),
    ));
  }

  _reconnectParticipantUsersSubscription() {
    _participantUsersSubscription.resubscribe((collectionReference) =>
        collectionReference.where(FieldPath.documentId, whereIn: getUserIds()));
  }

  List<String> getUserIds() {
    List<String> userIds = [];
    for (SessionParticipant participant in sessionParticipants) {
      var participantId = participant.participantId;
      if (participantId != null) {
        var rawUserId = UserFunctions.extractNumberId(participantId);
        if (rawUserId != null) {
          userIds.add(rawUserId);
        }
      }
    }
    return userIds;
  }

  _reconnectPracticeRecordSubscription() {
    _practiceRecordsSubscription.resubscribe((collectionReference) =>
        collectionReference
            .where('isGraduation', isEqualTo: true)
            .where('menteeUid', whereIn: getUserUids()));
  }

  List<String> getUserUids() {
    List<String> userUids = [];
    for (SessionParticipant participant in sessionParticipants) {
      var participantId = participant.participantId;
      if (participantId != null) {
        User? user = getUser(participant);
        if (user != null) {
          userUids.add(user.uid);
        }
      }
    }
    return userUids;
  }

  List<Lesson> getGraduatedLessons(SessionParticipant sessionParticipant) {
    List<Lesson> graduatedLessons = List.empty();

    User? user = getUser(sessionParticipant);
    if (user != null) {
      // Check if this is cached
      if (_userToGraduatedLessons.containsKey(user)) {
        return _userToGraduatedLessons[user]!;
      }

      for (PracticeRecord practiceRecord in practiceRecords) {
        if (practiceRecord.menteeUid == user.uid) {
          Lesson? lesson = _libraryState.findLesson(practiceRecord.lessonId.id);
          if (lesson != null) {
            graduatedLessons.add(lesson);
          }
        }
      }

      _userToGraduatedLessons[user] = List.from(graduatedLessons);
    }

    return graduatedLessons;
  }

  _subscribeToSession(String sessionId) {
    _sessionsSubscription.resubscribe(() => '/sessions/$sessionId');

    _sessionParticipantsSubscription.resubscribe((collectionReference) =>
        collectionReference.where('sessionId',
            isEqualTo: FirebaseFirestore.instance
                .doc('/sessions/${currentSession?.id}')));

    _sessionPairingSubscription.resubscribe((collectionReference) =>
        collectionReference.where('sessionId',
            isEqualTo: FirebaseFirestore.instance.doc('/sessions/$sessionId')));
  }

  User? getUser(SessionParticipant participant) {
    return _uidToUserMap[participant.participantUid];
  }

  void saveNextRound(PairedSession pairedSession) {
    // TODO: Implement

    // Determine the last round.

    // Save pairings.

    // Add unpaired students to the instructor session.
  }

  int getLatestRoundNumber() {
    // TODO: Implement
    return -1;
  }

  _handleSessionParticipantsUpdate(List<SessionParticipant> items) {
    var session = currentSession;
    if ((session != null) &&
        (sessionParticipants.length != session?.participantCount)) {
      // Update the session participant count.
      FirebaseFirestore.instance.collection('sessions').doc(session.id).set(
          {'participantCount': sessionParticipants.length},
          SetOptions(merge: true));
    }

    _reconnectParticipantUsersSubscription();
    _reconnectPracticeRecordSubscription();
  }
}

// TODO: about the teach and learn count on participants.
