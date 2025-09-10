import 'dart:math';

import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/session_participant.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/session_pairing/learner_pair.dart';
import 'package:social_learning/session_pairing/lesson_count_list.dart';
import 'package:social_learning/session_pairing/paired_session.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/organizer_session_state.dart';

class SessionPairingAlgorithm {
  PairedSession generateNextSessionPairing(
      OrganizerSessionState organizerSessionState, LibraryState libraryState) {
    // Generate all possible pairings.
    List<PairedSession> possiblePairings =
        _generatePossiblePairings(organizerSessionState, libraryState);
    print('(1) Generated possible pairings: ${possiblePairings.length}');
    for (var element in possiblePairings) {
      element.debugPrint();
    }

    // Remove pairs without a lesson.
    for (var pairedSession in possiblePairings) {
      pairedSession.removePairsWithoutLesson();
    }
    print('(2) Removed pairs without a lesson: ${possiblePairings.length}');

    // Only keep the pairings with the least amount of unpaired participants.
    _keepOnlyPairingsWithTheLeastUnpairedParticipants(possiblePairings);
    print(
        '(3) Removed pairings with the least amount of unpaired participants: ${possiblePairings.length}');

    // Only keep the pairings that balance out the best how much students have
    // taught and learned.
    _keepOnlyPairingsWithTheMostBalancedLearnTeachCount(possiblePairings);
    print(
        '(4) Removed pairings that balance out the best how much students have taught and learned: ${possiblePairings.length}');

    // Only keep the pairings that spread the rarest lessons. In the ideal case,
    // the rarest lesson is a lesson that no student knows and the instructor
    // introduces to the first student.
    possiblePairings = _returnOnlyPairingsWithTheRarestLessons(
        possiblePairings, organizerSessionState);
    print(
        '(5) Removed pairings that spread the rarest lessons: ${possiblePairings.length}');

    // TODO: Consider diversity.

    // TODO: Determine the possible pairings.
    // TODO: Pick the best pairing.
    // TODO: I think right now a teacher will teach the highest lesson, but it should be the highest connected lesson.
    return possiblePairings.first;
  }

  void _keepOnlyPairingsWithTheLeastUnpairedParticipants(
      List<PairedSession> possiblePairings) {
    if (possiblePairings.length > 1) {
      var minUnpairedParticipants = possiblePairings.fold<int>(
          possiblePairings.first.unpairedParticipants.length,
          (value, element) => min(value, element.unpairedParticipants.length));
      possiblePairings.removeWhere((pairedSession) =>
          pairedSession.unpairedParticipants.length > minUnpairedParticipants);
    }
  }

  List<PairedSession> _generatePossiblePairings(
      OrganizerSessionState organizerSessionState, LibraryState libraryState) {
    List<SessionParticipant> activeParticipants = List.from(
        organizerSessionState.sessionParticipants
            .where((participant) => participant.isActive));

    return _generatePairings(
        activeParticipants, [], organizerSessionState, libraryState);
  }

  List<PairedSession> _generatePairings(
      List<SessionParticipant> remainingParticipants,
      List<LearnerPair> currentPairs,
      OrganizerSessionState organizerSessionState,
      LibraryState libraryState) {
    if (remainingParticipants.length < 2) {
      return List.from([PairedSession(currentPairs, remainingParticipants)]);
    }

    List<PairedSession> pairings = [];

    for (int i = 1; i < remainingParticipants.length; i++) {
      List<SessionParticipant> thisParticipants =
          List.from(remainingParticipants);
      SessionParticipant participantA = thisParticipants.removeAt(0);
      SessionParticipant participantB = thisParticipants.removeAt(i - 1);

      // One way pair
      Lesson? lesson = _pickBestLesson(
          participantA, participantB, organizerSessionState, libraryState);

      LearnerPair pair = LearnerPair(
          participantA,
          organizerSessionState.getUser(participantA)!,
          participantB,
          organizerSessionState.getUser(participantB)!,
          lesson);

      pairings.addAll(_generatePairings(
          List.from(thisParticipants),
          List.from(currentPairs)..add(pair),
          organizerSessionState,
          libraryState));

      // TODO: Skip the reverse case when a user is an instructor.

      // Reverse pair
      Lesson? reverseLesson = _pickBestLesson(
          participantB, participantA, organizerSessionState, libraryState);
      LearnerPair reversePair = pair.reverse(reverseLesson);
      pairings.addAll(_generatePairings(
          List.from(thisParticipants),
          List.from(currentPairs)..add(reversePair),
          organizerSessionState,
          libraryState));
    }

    return pairings;
  }

  Lesson? _pickBestLesson(
      SessionParticipant participantA,
      SessionParticipant participantB,
      OrganizerSessionState organizerSessionState,
      LibraryState libraryState) {
    print('Picking best lesson for ${participantA.id} and ${participantB.id}');
    User? userA = organizerSessionState.getUser(participantA);
    List<Lesson> teachableLessons =
        organizerSessionState.getGraduatedLessons(participantA);

    User? userB = organizerSessionState.getUser(participantB);
    List<Lesson> alreadyLearnedLessons =
        organizerSessionState.getGraduatedLessons(participantB);

    // Handle the case where the user is an instructor.
    if (userB?.isAdmin ?? false) {
      // There is no point in teaching an instructor.
      return null;
    } else if (userA?.isAdmin ?? false) {
      // If the teacher is an instructor, pick the lesson that's next for the
      // learner.
      print('_pickBestLesson: instructor teaching');
      var tmp = libraryState.lessons;
      if (tmp != null) {
        List<Lesson> courseLessons = List.from(tmp);
        courseLessons.sort((lessonA, lessonB) =>
            lessonA.sortOrder.compareTo(lessonB.sortOrder));
        Set<Lesson> alreadyLearnedLessonsSet = alreadyLearnedLessons.toSet();
        for (var element in alreadyLearnedLessonsSet) {
          print('lesson learned: ${element.title}');
        }
        courseLessons
            .removeWhere((lesson) => alreadyLearnedLessonsSet.contains(lesson));
        return (courseLessons.isNotEmpty) ? courseLessons.first : null;
      }
    }

    // Find relevant lessons.
    Set<Lesson> possibleLessons =
        teachableLessons.toSet().difference(alreadyLearnedLessons.toSet());

    // Find the lesson with the lowest sort order.
    if (possibleLessons.isEmpty) {
      return null;
    } else {
      return possibleLessons.reduce((lessonA, lessonB) =>
          (lessonA.sortOrder < lessonB.sortOrder) ? lessonA : lessonB);
    }
  }

  void _keepOnlyPairingsWithTheMostBalancedLearnTeachCount(
      List<PairedSession> possiblePairings) {
    if (possiblePairings.length > 1) {
      List<int> learnTeachImbalances = possiblePairings
          .map<int>(
              (pairedSession) => pairedSession.calculateLearnTeachImbalance())
          .toList();
      var minImbalance = learnTeachImbalances.reduce(min);
      for (int i = learnTeachImbalances.length - 1; i >= 0; i--) {
        if (learnTeachImbalances[i] > minImbalance) {
          possiblePairings.removeAt(i);
        }
      }
    }
  }

  List<PairedSession> _returnOnlyPairingsWithTheRarestLessons(
      List<PairedSession> possiblePairings,
      OrganizerSessionState organizerSessionState) {
    if (possiblePairings.length > 1) {
      List<LessonCountList> lessonCountLists = [];

      // Prepare data for easy access.
      for (PairedSession pairedSession in possiblePairings) {
        List<Lesson> activeLessons =
            pairedSession.calculateActiveLessons().toList();

        var graduatedLessonCounts =
            pairedSession.calculateGraduatedLessons(organizerSessionState);

        LessonCountList lessonCountList = LessonCountList(
            pairedSession, activeLessons, graduatedLessonCounts);
        lessonCountLists.add(lessonCountList);
      }

      // Sort pairings by the rarest lessons.
      lessonCountLists.sort();

      LessonCountList firstCountList = lessonCountLists.first;
      for (int i = 1; i < lessonCountLists.length; i++) {
        if (lessonCountLists[i].compareTo(firstCountList) != 0) {
          return lessonCountLists
              .sublist(0, i)
              .map((e) => e.pairedSession)
              .toList();
        }
      }

      return lessonCountLists.map((e) => e.pairedSession).toList();
    }

    return possiblePairings;
  }
}
