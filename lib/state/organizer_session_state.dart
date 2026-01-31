import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/data_helpers/reference_helper.dart';
import 'package:social_learning/data/data_helpers/session_functions.dart';
import 'package:social_learning/data/data_helpers/session_pairing_functions.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/practice_record.dart';
import 'package:social_learning/data/session.dart';
import 'package:social_learning/data/session_pairing.dart';
import 'package:social_learning/data/session_participant.dart';
import 'package:social_learning/data/session_type.dart';
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
import 'package:social_learning/state/graduation_status.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/data/data_helpers/session_participant_functions.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

class OrganizerSessionState extends ChangeNotifier {
  final LibraryState _libraryState;

  bool get isInitialized => _sessionSubscription.isInitialized;

  // new subscriptions
  late SessionSubscription _sessionSubscription;

  late SessionParticipantsSubscription _sessionParticipantsSubscription;

  late ParticipantUsersSubscription _participantUsersSubscription;

  late PracticeRecordsSubscription _practiceRecordsSubscription;

  late SessionPairingsSubscription _sessionPairingSubscription;

  Session? get currentSession => _sessionSubscription.item;

  List<SessionParticipant> get sessionParticipants =>
      _sessionParticipantsSubscription.items;

  List<User> get participantUsers => _participantUsersSubscription.items;

  List<PracticeRecord> get practiceRecords =>
      _practiceRecordsSubscription.items;

  Map<int, List<SessionPairing>> get roundNumberToSessionPairing =>
      _sessionPairingSubscription.roundNumberToSessionPairings;

  List<SessionPairing>? get lastRound =>
      _sessionPairingSubscription.getLastRound();

  List<SessionPairing> get allPairings => _sessionPairingSubscription.items;

  OrganizerSessionState(ApplicationState applicationState, this._libraryState) {
    // Start subscriptions.
    _sessionSubscription = SessionSubscription(() => notifyListeners());

    _practiceRecordsSubscription = PracticeRecordsSubscription(
      () => notifyListeners(),
      _libraryState,
    );

    _participantUsersSubscription = ParticipantUsersSubscription(
      () => notifyListeners(),
      _practiceRecordsSubscription,
    );

    _sessionParticipantsSubscription = SessionParticipantsSubscription(
      true,
      false,
      () => notifyListeners(),
      _sessionSubscription,
      _participantUsersSubscription,
      null,
    );

    _sessionPairingSubscription = SessionPairingsSubscription(
      () => _handleSessionPairingsUpdated(),
    );

    // Check if the user logged back into the app with a running session.
    _connectToActiveSession(applicationState);

    applicationState.addListener(() {
      _connectToActiveSession(applicationState);
    });

    _libraryState.addListener(() => _handleCourseChange(applicationState));
  }

  int get maxRoundNumber => allPairings
      .fold(0, (maxSoFar, pairing) => max(maxSoFar, pairing.roundNumber));

  void _connectToActiveSession(ApplicationState applicationState) {
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
              'Got active session where this user is the organiser: ${snapshot.docs.length}, incomplete: ${snapshot.metadata.hasPendingWrites}',
            );
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
          })
          .onError((error, stackTrace) {
            print('Failed to get active session from Firestore: $error');
          });
    }
  }

  Future<void> createSession(
    String sessionName,
    ApplicationState applicationState,
    LibraryState libraryState,
    SessionType sessionType, {
    bool includeHostInPairing = true,
  }) async {
    User? organizer = applicationState.currentUser;
    Course? course = libraryState.selectedCourse;

    if (organizer == null) {
      snackbarKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text(
            "Failed to create session because you are not logged in.",
          ),
        ),
      );
      return;
    }

    if (course == null) {
      snackbarKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text(
            "Failed to create session because no course is selected.",
          ),
        ),
      );
      return;
    }

    DocumentReference<Map<String, dynamic>> sessionDoc =
        await SessionFunctions.createSession(
          courseId: course.id!,
          sessionName: sessionName,
          organizerUid: organizer.uid,
          organizerName: organizer.displayName,
          sessionType: sessionType,
          includeHostInPairing: includeHostInPairing,
        );
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

    snackbarKey.currentState?.showSnackBar(
      SnackBar(content: Text('Successfully created session $sessionId')),
    );
  }

  void _subscribeToSession(String sessionId) {
    _sessionSubscription.resubscribe(() => '/sessions/$sessionId');

    _sessionParticipantsSubscription.resubscribe(
      (collectionReference) => SessionParticipantFunctions.queryBySessionId(
        collectionReference,
        sessionId,
      ),
    );

    _sessionPairingSubscription.resubscribe(
      (collectionReference) => collectionReference.where(
        'sessionId',
        isEqualTo: docRef('sessions', sessionId),
      ),
    );
  }

  NavigationEnum getActiveSessionNavigationEnum({SessionType? sessionType}) {
    SessionType? targetSessionType = sessionType ?? currentSession?.sessionType;

    if (targetSessionType == null) {
      return NavigationEnum.sessionHome;
    }

    switch (targetSessionType) {
      case SessionType.automaticManual:
        return NavigationEnum.sessionHost;
      case SessionType.powerMode:
        return NavigationEnum.advancedPairingHost;
      case SessionType.partyModeDuo:
      case SessionType.partyModeTrio:
        return NavigationEnum.partyPairingHost;
    }
  }

  void navigateToActiveSessionPage(
    BuildContext context, {
    SessionType? sessionType,
  }) {
    NavigationEnum? destination = getActiveSessionNavigationEnum(
      sessionType: sessionType,
    );

    if (destination != null) {
      destination.navigateClean(context);
    }
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
            'sessionId': docRef('sessions', currentSession!.id!),
            'roundNumber': currentRound,
            'mentorId': docRef(
              'users',
              pair.teachingParticipant.participantId.id,
            ),
            'menteeId': docRef(
              'users',
              pair.learningParticipant.participantId.id,
            ),
            'lessonId': docRef('lessons', pair.lesson!.id!),
            'additionalStudentIds': [],
          })
          .catchError((error) {
            print('Failed to save session pairing: $error');
          });
      print('Saved session pair.');
    }

    // Add unpaired students to the instructor session.
    // TODO: Implement
  }

  User? getUser(SessionParticipant sessionParticipant) =>
      _participantUsersSubscription.getUser(sessionParticipant);

  User? getUserByParticipantId(String? participantId) {
    if (participantId == null) {
      return null;
    }
    SessionParticipant? participant = _sessionParticipantsSubscription
        .getParticipantByParticipantId(participantId);

    if (participant == null) {
      print('Participant not found for participantId $participantId');
      return null;
    }
    return _participantUsersSubscription.getUser(participant);
  }

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

  SessionParticipant? getParticipantByUserId(String? userId) {
    if (userId == null) {
      return null;
    }
    return _sessionParticipantsSubscription.getParticipantByUserId(userId);
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
    docRef('sessions', currentSession!.id!).update({'isActive': false});

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
    docRef('sessionPairings', sessionPairing.id!)
        .update({'mentorId': null})
        .then((value) {
          print('Removed mentor from session pairing.');
        })
        .catchError((error) {
          print('Failed to remove mentor from session pairing: $error');
        });
  }

  void removeMentee(SessionPairing sessionPairing) {
    docRef('sessionPairings', sessionPairing.id!)
        .update({'menteeId': null})
        .then((value) {
          print('Removed mentee from session pairing.');
        })
        .catchError((error) {
          print('Failed to remove mentee from session pairing: $error');
        });
  }

  void addMentor(User selectedUser, SessionPairing sessionPairing) {
    docRef('sessionPairings', sessionPairing.id!)
        .update({
          'mentorId': FirebaseFirestore.instance.doc(
            '/users/${selectedUser.id}',
          ),
        })
        .then((value) {
          print('Added mentor to session pairing.');
        })
        .catchError((error) {
          print('Failed to add mentor to session pairing: $error');
        });
  }

  void addMentee(User selectedUser, SessionPairing sessionPairing) {
    docRef('sessionPairings', sessionPairing.id!)
        .update({
          'menteeId': FirebaseFirestore.instance.doc(
            '/users/${selectedUser.id}',
          ),
        })
        .then((value) {
          print('Added mentee to session pairing.');
        })
        .catchError((error) {
          print('Failed to add mentee to session pairing: $error');
        });
  }

  bool hasUserGraduatedLesson(User user, Lesson lesson) {
    return _practiceRecordsSubscription.hasUserGraduatedLesson(user, lesson);
  }

  void removeLesson(SessionPairing sessionPairing) {
    SessionPairingFunctions.removeLesson(sessionPairing);
  }

  void updateLesson(Lesson lesson, SessionPairing sessionPairing) {
    SessionPairingFunctions.updateLesson(sessionPairing, lesson);
  }

  void updateStudentsAndLesson(
    String pairingId,
    String? mentorUserId,
    String? menteeUserId,
    List<String>? additionalStudentUserIds,
    String? lessonId,
    WriteBatch batch,
  ) {
    SessionPairingFunctions.updateStudentsAndLesson(
      pairingId,
      mentorUserId,
      menteeUserId,
      additionalStudentUserIds,
      lessonId,
      batch,
    );
  }

  String addPairing(SessionPairing pairing, WriteBatch batch) {
    return SessionPairingFunctions.addPairing(pairing, batch);
  }

  void removePairing(String pairingId, WriteBatch batch) {
    SessionPairingFunctions.removePairing(pairingId, batch);
  }

  void _handleCourseChange(ApplicationState applicationState) {
    if (currentSession?.courseId.id != _libraryState.selectedCourse?.id) {
      _disconnectFromSession();
      notifyListeners();
      _connectToActiveSession(applicationState);
    }
  }

  Future<void> completePairing(String pairingId) async {
    await SessionPairingFunctions.completePairing(pairingId);
  }

  Future<void> _handleSessionPairingsUpdated() async {
    notifyListeners();
    await _updateTeachAndLearnCountsFromPairings();
  }

  Future<void> _updateTeachAndLearnCountsFromPairings() async {
    if (!_shouldUpdateTeachAndLearnCounts()) {
      return;
    }

    final teachCounts = <String, int>{};
    final learnCounts = <String, int>{};

    for (final pairing in _sessionPairingSubscription.items.where(
      (pairing) => pairing.isCompleted,
    )) {
      final mentorId = pairing.mentorId?.id;
      if (mentorId != null) {
        teachCounts[mentorId] = (teachCounts[mentorId] ?? 0) + 1;
      }

      final menteeId = pairing.menteeId?.id;
      if (menteeId != null) {
        learnCounts[menteeId] = (learnCounts[menteeId] ?? 0) + 1;
      }

      for (final additionalStudent in pairing.additionalStudentIds) {
        learnCounts[additionalStudent.id] =
            (learnCounts[additionalStudent.id] ?? 0) + 1;
      }
    }

    List<SessionParticipant> dirtyParticipants = [];
    for (final participant in sessionParticipants) {
      if (participant.id == null) {
        continue;
      }

      final userId = participant.participantId.id;
      final newTeachCount = teachCounts[userId] ?? 0;
      final newLearnCount = learnCounts[userId] ?? 0;

      if (participant.teachCount != newTeachCount ||
          participant.learnCount != newLearnCount) {
        participant.teachCount = newTeachCount;
        participant.learnCount = newLearnCount;
        dirtyParticipants.add(participant);
      }
    }

    if (dirtyParticipants.isNotEmpty) {
      await SessionParticipantFunctions.updateTeachAndLearnCounts(
        dirtyParticipants,
      );
    }
  }

  bool _shouldUpdateTeachAndLearnCounts() {
    final session = currentSession;
    return session != null &&
        _sessionPairingSubscription.isInitialized &&
        _sessionParticipantsSubscription.isInitialized &&
        (session.sessionType == SessionType.powerMode ||
            session.sessionType == SessionType.partyModeDuo ||
            session.sessionType == SessionType.partyModeTrio);
  }

  /// The learn to teach ratio is useful to calculate the teaching deficit. In
  /// some sessions, more than one student learn from a mentor. So to balance
  /// out learning and teaching, students have to teach less.
  double getLearnTeachRatio() {
    int teachCount = 0;
    int learnCount = 0;

    for (SessionPairing pairing in allPairings) {
      if (pairing.isCompleted) {
        if (pairing.mentorId != null) {
          teachCount++;
        }
        if (pairing.menteeId != null) {
          learnCount++;
        }
        learnCount += pairing.additionalStudentIds.length;
      }
    }

    return learnCount / teachCount;
  }

  GraduationStatus getGraduationStatus(
    SessionParticipant participant,
    Lesson lesson,
  ) {
    Timestamp? sessionStart = currentSession?.startTime;
    GraduationStatus status = GraduationStatus.untouched;

    for (PracticeRecord practiceRecord in practiceRecords) {
      if (practiceRecord.menteeUid == participant.participantUid &&
          practiceRecord.lessonId.id == lesson.id) {
        if (practiceRecord.isGraduation) {
          return GraduationStatus.graduated;
        } else if (sessionStart != null &&
            practiceRecord.timestamp != null &&
            sessionStart.toDate().isBefore(
              practiceRecord.timestamp!.toDate(),
            )) {
          status = GraduationStatus.practicedThisSession;
        }
        if (status == GraduationStatus.untouched) {
          status = GraduationStatus.practiced;
        }
      }
    }

    return status;
  }

  SessionPairing? getPairingById(String pairingId) {
    return allPairings.firstWhereOrNull((pairing) => pairing.id == pairingId);
  }
}

// TODO: about the teach and learn count on participants.
