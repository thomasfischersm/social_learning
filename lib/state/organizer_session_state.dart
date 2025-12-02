import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/data_helpers/reference_helper.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/session.dart';
import 'package:social_learning/data/session_pairing.dart';
import 'package:social_learning/data/session_participant.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/globals.dart';
import 'package:social_learning/session_pairing/learner_pair.dart';
import 'package:social_learning/session_pairing/paired_session.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/firestore_subscription/participant_users_subscription.dart';
import 'package:social_learning/state/firestore_subscription/practice_records_subscription.dart';
import 'package:social_learning/state/firestore_subscription/session_pairings_subscription.dart';
import 'package:social_learning/state/firestore_subscription/session_participants_subscription.dart';
import 'package:social_learning/state/firestore_subscription/session_subscription.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/data/data_helpers/session_participant_functions.dart';

class OrganizerSessionState extends ChangeNotifier {
  final LibraryState _libraryState;

  get isInitialized => _sessionSubscription.isInitialized;

  // new subscriptions
  late SessionSubscription _sessionSubscription;

  late SessionParticipantsSubscription _sessionParticipantsSubscription;

  late ParticipantUsersSubscription _participantUsersSubscription;

  late PracticeRecordsSubscription _practiceRecordsSubscription;

  late SessionPairingsSubscription _sessionPairingSubscription;

  get currentSession => _sessionSubscription.item;

  List<SessionParticipant> get sessionParticipants => _sessionParticipantsSubscription.items;

  get participantUsers => _participantUsersSubscription.items;

  get practiceRecords => _practiceRecordsSubscription.items;

  get roundNumberToSessionPairing =>
      _sessionPairingSubscription.roundNumberToSessionPairings;

  List<SessionPairing>? get lastRound =>
      _sessionPairingSubscription.getLastRound();

  OrganizerSessionState(ApplicationState applicationState, this._libraryState) {
    // Start subscriptions.
    _sessionSubscription = SessionSubscription(() => notifyListeners());

    _practiceRecordsSubscription =
        PracticeRecordsSubscription(() => notifyListeners(), _libraryState);

    _participantUsersSubscription = ParticipantUsersSubscription(
        () => notifyListeners(), _practiceRecordsSubscription);

    _sessionParticipantsSubscription = SessionParticipantsSubscription(
        true,
        false,
        () => notifyListeners(),
        _sessionSubscription,
        _participantUsersSubscription,
        null);

    _sessionPairingSubscription =
        SessionPairingsSubscription(() => notifyListeners());

    // Check if the user logged back into the app with a running session.
    _connectToActiveSession(applicationState);

    applicationState.addListener(() {
      _connectToActiveSession(applicationState);
    });

    _libraryState.addListener(() => _handleCourseChange(applicationState));
  }

  _connectToActiveSession(ApplicationState applicationState) {
    var uid = applicationState.currentUser?.uid;
    var courseId = _libraryState.selectedCourse?.id;

    if (uid != null && courseId != null) {
      FirebaseFirestore.instance
          .collection('sessions')
          .where('organizerUid', isEqualTo: uid)
          .where('isActive', isEqualTo: true)
          .where('courseId', isEqualTo: docRef('courses', courseId))
          .get()
          .then((snapshot) {
        print(
            'Got active session where this user is the organiser: ${snapshot.docs.length}, incomplete: ${snapshot.metadata.hasPendingWrites}');
        if ((snapshot.size > 0) && !snapshot.metadata.hasPendingWrites) {
          var session = Session.fromQuerySnapshot(snapshot.docs.first);
          // Only enter the session if it belongs to the currently selected course.
          var selectedCourseId = _libraryState.selectedCourse?.id;
          if (selectedCourseId == session.courseId.id) {
            String sessionId = session.id!;
            _subscribeToSession(sessionId);
            _sessionSubscription.loadItemManually(session);
          } else {
            print('Active session found for a different course; ignoring.');
          }
        }
      }).onError((error, stackTrace) {
        print('Failed to get active session from Firestore: $error');
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
    await SessionParticipantFunctions.createParticipant(
      sessionId: sessionId,
      userId: organizer.id,
      userUid: organizer.uid,
      courseId: course.id!,
      isInstructor: organizer.isAdmin,
    );
    print('after creating participant');

    // Listen to session changes.
    _subscribeToSession(sessionId);

    notifyListeners();

    snackbarKey.currentState?.showSnackBar(SnackBar(
      content: Text('Successfully created session $sessionId'),
    ));
  }

  _subscribeToSession(String sessionId) {
    _sessionSubscription.resubscribe(() => '/sessions/$sessionId');

    _sessionParticipantsSubscription.resubscribe((collectionReference) =>
        SessionParticipantFunctions.queryBySessionId(
            collectionReference, sessionId));

    _sessionPairingSubscription.resubscribe((collectionReference) =>
        collectionReference.where('sessionId',
            isEqualTo: FirebaseFirestore.instance.doc('/sessions/$sessionId')));
  }

  void saveNextRound(PairedSession pairedSession) {
    // TODO: Implement

    // Determine the last round.
    int currentRound = _sessionPairingSubscription.getLatestRoundNumber() + 1;
    print('Next round number is $currentRound');

    // Save pairings.
    for (LearnerPair pair in pairedSession.pairs) {
      FirebaseFirestore.instance
          .collection('sessionPairings')
          .add(<String, dynamic>{
        'sessionId':
            FirebaseFirestore.instance.doc('/sessions/${currentSession?.id}'),
        'roundNumber': currentRound,
        'mentorId': FirebaseFirestore.instance
            .doc('/users/${pair.teachingParticipant.participantId.id}'),
        'menteeId': FirebaseFirestore.instance
            .doc('/users/${pair.learningParticipant.participantId.id}'),
        'lessonId':
            FirebaseFirestore.instance.doc('/lessons/${pair.lesson!.id}'),
        'additionalStudentIds': [],
      }).catchError((error) {
        print('Failed to save session pairing: $error');
      });
      print('Saved session pair.');
    }

    // Add unpaired students to the instructor session.
    // TODO: Implement
  }

  User? getUser(SessionParticipant sessionParticipant) =>
      _participantUsersSubscription.getUser(sessionParticipant);

  User? getUserById(String? id) =>
      (id == null) ? null : _participantUsersSubscription.getUserById(id);

  List<Lesson> getGraduatedLessons(SessionParticipant participant) {
    var user = getUser(participant);
    if (user != null) {
      return _practiceRecordsSubscription.getGraduatedLessons(user);
    } else {
      return [];
    }
  }

  void signOut() {
    _disconnectFromSession();
  }

  void _disconnectFromSession() {
    _sessionSubscription.cancel();
    _sessionParticipantsSubscription.cancel();
    _participantUsersSubscription.cancel();
    _practiceRecordsSubscription.cancel();
    _sessionPairingSubscription.cancel();
  }

  void endSession() {
    // Set the session to inactive.
    FirebaseFirestore.instance
        .doc('/sessions/${currentSession?.id}')
        .update({'isActive': false});

    _sessionSubscription.cancel();
    _sessionParticipantsSubscription.cancel();
    _participantUsersSubscription.cancel();
    _practiceRecordsSubscription.cancel();
    _sessionPairingSubscription.cancel();
  }

  void endCurrentRound() async {
    // TODO: This doesn't really work because we can't modify the SessionParticipant
    // documents that are owned by the session participants!

    //   print('Ending the current round');
    //
    //   List<SessionPairing>? currentRound =
    //       _sessionPairingSubscription.getLastRound();
    //
    //   if (currentRound != null) {
    //     List<Future<void>> updateFutures = [];
    //
    //     for (SessionPairing pairing in currentRound) {
    //       // Increase the teach count for the mentor.
    //       print('Incrementing teach count for ${pairing.mentorId.id}');
    //       updateFutures.add(FirebaseFirestore.instance
    //           .doc('/sessionParticipants/${pairing.mentorId.id}')
    //           .update({'teachCount': FieldValue.increment(1)}));
    //
    //       // Increase the learn count for the mentee.
    //       print('Incrementing learn count for ${pairing.menteeId.id}');
    //       updateFutures.add(FirebaseFirestore.instance
    //           .doc('/sessionParticipants/${pairing.menteeId.id}')
    //           .update({'learnCount': FieldValue.increment(1)}));
    //     }
    //
    //     await Future.wait(updateFutures);
    //   }
  }

  int getTeachCountForUser(String userId) {
    return _sessionPairingSubscription.items
        .where((pairing) => pairing.mentorId?.id == userId)
        .length;
  }

  int getLearnCountForUser(String userId) {
    return _sessionPairingSubscription.items
        .where((pairing) => pairing.menteeId?.id == userId)
        .length;
  }

  void removeMentor(SessionPairing sessionPairing) {
    FirebaseFirestore.instance
        .doc('/sessionPairings/${sessionPairing.id}')
        .update({
      'mentorId': null,
    }).then((value) {
      print('Removed mentor from session pairing.');
    }).catchError((error) {
      print('Failed to remove mentor from session pairing: $error');
    });
  }

  void removeMentee(SessionPairing sessionPairing) {
    FirebaseFirestore.instance
        .doc('/sessionPairings/${sessionPairing.id}')
        .update({
      'menteeId': null,
    }).then((value) {
      print('Removed mentee from session pairing.');
    }).catchError((error) {
      print('Failed to remove mentee from session pairing: $error');
    });
  }

  void addMentor(User selectedUser, SessionPairing sessionPairing) {
    FirebaseFirestore.instance
        .doc('/sessionPairings/${sessionPairing.id}')
        .update({
      'mentorId': FirebaseFirestore.instance.doc('/users/${selectedUser.id}'),
    }).then((value) {
      print('Added mentor to session pairing.');
    }).catchError((error) {
      print('Failed to add mentor to session pairing: $error');
    });
  }

  void addMentee(User selectedUser, SessionPairing sessionPairing) {
    FirebaseFirestore.instance
        .doc('/sessionPairings/${sessionPairing.id}')
        .update({
      'menteeId': FirebaseFirestore.instance.doc('/users/${selectedUser.id}'),
    }).then((value) {
      print('Added mentee to session pairing.');
    }).catchError((error) {
      print('Failed to add mentee to session pairing: $error');
    });
  }

  bool hasUserGraduatedLesson(User user, Lesson lesson) {
    return _practiceRecordsSubscription.hasUserGraduatedLesson(user, lesson);
  }

  void removeLesson(SessionPairing sessionPairing) {
    FirebaseFirestore.instance
        .doc('/sessionPairings/${sessionPairing.id}')
        .update({
      'lessonId': null,
    }).then((value) {
      print('Removed lesson from session pairing.');
    }).catchError((error) {
      print('Failed to remove lesson from session pairing: $error');
    });
  }

  void addLesson(Lesson lesson, SessionPairing sessionPairing) {
    FirebaseFirestore.instance
        .doc('/sessionPairings/${sessionPairing.id}')
        .update({
      'lessonId': FirebaseFirestore.instance.doc('/lessons/${lesson.id}'),
    }).then((value) {
      print('Added lesson to session pairing.');
    }).catchError((error) {
      print('Failed to add lesson to session pairing: $error');
    });
  }

  void _handleCourseChange(ApplicationState applicationState) {
    if (currentSession?.courseId.id != _libraryState.selectedCourse?.id) {
      _disconnectFromSession();
      notifyListeners();
      _connectToActiveSession(applicationState);
    }
  }
}

// TODO: about the teach and learn count on participants.
