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
import 'package:social_learning/globals.dart';
import 'package:social_learning/session_pairing/learner_pair.dart';
import 'package:social_learning/session_pairing/paired_session.dart';
import 'package:social_learning/session_pairing/session_pairing_algorithm.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/firestore_subscription/firestore_document_subscription.dart';
import 'package:social_learning/state/firestore_subscription/firestore_list_subscription.dart';
import 'package:social_learning/state/firestore_subscription/participant_users_subscription.dart';
import 'package:social_learning/state/firestore_subscription/practice_records_subscription.dart';
import 'package:social_learning/state/firestore_subscription/session_pairings_subscription.dart';
import 'package:social_learning/state/firestore_subscription/session_participants_subscription.dart';
import 'package:social_learning/state/firestore_subscription/session_subscription.dart';
import 'package:social_learning/state/library_state.dart';

class OrganizerSessionState extends ChangeNotifier {
  final LibraryState _libraryState;

  get isInitialized => _sessionsSubscription.isInitialized;

  // new subscriptions
  late SessionSubscription _sessionsSubscription;

  late SessionParticipantsSubscription _sessionParticipantsSubscription;

  late ParticipantUsersSubscription _participantUsersSubscription;

  late PracticeRecordsSubscription _practiceRecordsSubscription;

  late SessionPairingsSubscription _sessionPairingSubscription;

  get currentSession => _sessionsSubscription.item;

  get sessionParticipants => _sessionParticipantsSubscription.items;

  get participantUsers => _participantUsersSubscription.items;

  get practiceRecords => _practiceRecordsSubscription.items;

  OrganizerSessionState(ApplicationState applicationState, this._libraryState) {
    // Start subscriptions.
    _sessionsSubscription = SessionSubscription(() => notifyListeners());

    _practiceRecordsSubscription =
        PracticeRecordsSubscription(() => notifyListeners(), _libraryState);

    _participantUsersSubscription = ParticipantUsersSubscription(
        () => notifyListeners(), _practiceRecordsSubscription);

    _sessionParticipantsSubscription = SessionParticipantsSubscription(
        () => notifyListeners(),
        _sessionsSubscription,
        _participantUsersSubscription);

    _sessionPairingSubscription =
        SessionPairingsSubscription(() => notifyListeners());

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
          .where('isActive', isEqualTo: true)
          .get()
          .then((snapshot) {
        print(
            'Got active session where this user is the organiser: ${snapshot.docs.length}, incomplete: ${snapshot.metadata.hasPendingWrites}');
        if ((snapshot.size > 0) && !snapshot.metadata.hasPendingWrites) {
          var session = Session.fromQuerySnapshot(snapshot.docs.first);
          String sessionId = session.id!;
          // _currentSession = session;

          _subscribeToSession(sessionId);
          _sessionsSubscription.loadItemManually(session);

          // Check if the right course is selected and switch if necessary.
          if (_libraryState.selectedCourse?.id != session.courseId.id) {
            print('Need to select course: ${_libraryState.availableCourses.length}');
            // TODO: There is a timing bug. Courses won't have loaded yet at startup.
            var courses = _libraryState.availableCourses
                .where((course) => course.id == session.courseId.id);
            if (courses.isNotEmpty) {
              _libraryState.selectedCourse = courses.first;
              print('Auto-selected course because of active session: ${courses.first.title}');
            }
          }
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

  _subscribeToSession(String sessionId) {
    _sessionsSubscription.resubscribe(() => '/sessions/$sessionId');

    _sessionParticipantsSubscription.resubscribe((collectionReference) =>
        collectionReference.where('sessionId',
            isEqualTo: FirebaseFirestore.instance.doc('/sessions/$sessionId')));

    _sessionPairingSubscription.resubscribe((collectionReference) =>
        collectionReference.where('sessionId',
            isEqualTo: FirebaseFirestore.instance.doc('/sessions/$sessionId')));
  }

  void saveNextRound(PairedSession pairedSession) {
    // TODO: Implement

    // Determine the last round.
    int currentRound = _sessionPairingSubscription.getLatestRoundNumber() + 1;

    // Save pairings.
    for (LearnerPair pair in pairedSession.pairs) {
      FirebaseFirestore.instance
          .collection('sessionPairings')
          .add(<String, dynamic>{
        'sessionId':
            FirebaseFirestore.instance.doc('/sessions/${currentSession?.id}'),
        'roundNumber': currentRound,
        'mentorId': FirebaseFirestore.instance
            .doc('/users/${pair.teachingParticipant.id}'),
        'menteeId': FirebaseFirestore.instance
            .doc('/users/${pair.learningParticipant.id}'),
        'lessonId':
            FirebaseFirestore.instance.doc('/lessons/${pair.lesson!.id}'),
      });
    }

    // Add unpaired students to the instructor session.
    // TODO: Implement
  }

  User? getUser(SessionParticipant sessionParticipant) =>
      _participantUsersSubscription.getUser(sessionParticipant);

  List<Lesson> getGraduatedLessons(SessionParticipant participant) {
    var user = getUser(participant);
    if (user != null) {
      return _practiceRecordsSubscription.getGraduatedLessons(user);
    } else {
      return [];
    }
  }
}

// TODO: about the teach and learn count on participants.
