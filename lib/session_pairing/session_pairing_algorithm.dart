import 'dart:math';

import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/session_participant.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/organizer_session_state.dart';

class SessionPairingAlgorithm {
  PairedSession generateNextSessionPairing(
      OrganizerSessionState organizerSessionState, LibraryState libraryState) {
    // Generate all possible pairings.
    List<PairedSession> possiblePairings =
        _generatePossiblePairings(organizerSessionState, libraryState);

    // Remove pairs without a lesson.
    for (var pairedSession in possiblePairings) {
      pairedSession.removePairsWithoutLesson();
    }

    // Only keep the pairings with the least amount of unpaired participants.
    _keepOnlyPairingsWithTheLeastUnpairedParticipants(possiblePairings);

    // Only keep the pairings that balance out the best how much students have
    // taught and learned.
    _keepOnlyPairingsWithTheMostBalancedLearnTeachCount(possiblePairings);

    // Only keep the pairings that spread the rarest lessons. In the ideal case,
    // the rarest lesson is a lesson that no student knows and the instructor
    // introduces to the first student.
    possiblePairings = _returnOnlyPairingsWithTheRarestLessons(
        possiblePairings, organizerSessionState);

    // TODO: Consider diversity.

    // TODO: Determine the possible pairings.
    // TODO: Pick the best pairing.
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
    List<SessionParticipant> allParticipants =
        List.from(organizerSessionState.sessionParticipants);

    return _generatePairings(
        allParticipants, [], organizerSessionState, libraryState);
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
      SessionParticipant participantB = thisParticipants.removeAt(i);

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
          participantA, participantB, organizerSessionState, libraryState);
      LearnerPair reversePair = pair.reverse(lesson);
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
      var tmp = libraryState.lessons;
      if (tmp != null) {
        List<Lesson> courseLessons = List.from(tmp);
        courseLessons.sort((lessonA, lessonB) =>
            lessonA.sortOrder.compareTo(lessonB.sortOrder));
        Set<Lesson> alreadyLearnedLessonsSet = alreadyLearnedLessons.toSet();
        courseLessons
            .removeWhere((lesson) => alreadyLearnedLessonsSet.contains(lesson));
        return (courseLessons.isNotEmpty) ? courseLessons.first : null;
      }
    }

    // Find relevant lessons.
    Set<Lesson> possibleLessons =
        teachableLessons.toSet().difference(alreadyLearnedLessons.toSet());

    // Find the lesson with the highest sort order.
    if (possibleLessons.isEmpty) {
      return null;
    } else {
      return possibleLessons.reduce((lessonA, lessonB) =>
          (lessonA.sortOrder > lessonB.sortOrder) ? lessonA : lessonB);
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

class LearnerPair {
  SessionParticipant teachingParticipant;
  User teachingUser;
  SessionParticipant learningParticipant;
  User learningUser;
  Lesson? lesson;

  LearnerPair(this.teachingParticipant, this.teachingUser,
      this.learningParticipant, this.learningUser, this.lesson);

  LearnerPair reverse(Lesson? reverseLesson) {
    return LearnerPair(learningParticipant, learningUser, teachingParticipant,
        teachingUser, reverseLesson);
  }
}

class PairedSession {
  List<LearnerPair> pairs;
  List<SessionParticipant> unpairedParticipants;

  PairedSession(this.pairs, this.unpairedParticipants);

// TODO: Remove pairings that don't have a lesson to teach.

  removePairsWithoutLesson() {
    pairs.removeWhere((pair) {
      if (pair.lesson == null) {
        unpairedParticipants.add(pair.teachingParticipant);
        unpairedParticipants.add(pair.learningParticipant);
        return true;
      } else {
        return false;
      }
    });
  }

  int calculateLearnTeachImbalance() {
    return pairs.fold<int>(
        0,
        (previousValue, pair) =>
            previousValue +
            (pair.teachingParticipant.learnCount -
                    pair.teachingParticipant.teachCount)
                .abs());
  }

  Set<Lesson> calculateActiveLessons() {
    return pairs.map((pair) => pair.lesson!).toSet();
  }

  Map<Lesson, int> calculateGraduatedLessons(
      OrganizerSessionState organizerSessionState) {
    List<SessionParticipant> participants =
        organizerSessionState.sessionParticipants;

    Map<Lesson, int> graduatedLessons = {};

    for (SessionParticipant participant in participants) {
      User? user = organizerSessionState.getUser(participant);
      if (user?.isAdmin ?? true) {
        List<Lesson> lessons =
            organizerSessionState.getGraduatedLessons(participant);
        for (Lesson lesson in lessons) {
          if (graduatedLessons.containsKey(lesson)) {
            graduatedLessons[lesson] = graduatedLessons[lesson]! + 1;
          } else {
            graduatedLessons[lesson] = 1;
          }
        }
      }
    }

    return graduatedLessons;
  }
}

/// A holder for all the lesson counts of a pairing. This makes it easier to
/// compare which offers the rarest lessons.
class LessonCountList implements Comparable<LessonCountList> {
  PairedSession pairedSession;
  List<LessonCountComparable> counts = [];

  LessonCountList(this.pairedSession, List<Lesson> activeLessons,
      Map<Lesson, int> graduatedLessonCounts) {
    Map<int, LessonCountComparable> graduatedCountToComparable = {};
    for (Lesson lesson in activeLessons.toSet()) {
      var graduatedLessonCount = graduatedLessonCounts[lesson] ?? 0;
      if (graduatedCountToComparable.containsKey(graduatedLessonCounts)) {
        LessonCountComparable comparable =
            graduatedCountToComparable[graduatedLessonCount]!;
        comparable.activeLessonCount++;
      } else {
        graduatedCountToComparable[graduatedLessonCount] =
            LessonCountComparable(graduatedLessonCount, 1);
      }
    }

    counts = graduatedCountToComparable.values.toList()..sort();
  }

  @override
  int compareTo(LessonCountList other) {
    for (int i = 0; i < counts.length; i++) {
      if (counts[i].compareTo(other.counts[i]) != 0) {
        return counts[i].compareTo(other.counts[i]);
      }
    }

    return 0;
  }
}

/// A Helper class to compare with pairing introduces rarer lessons.
class LessonCountComparable implements Comparable<LessonCountComparable> {
  int graduatedLessonCount;
  int activeLessonCount;

  LessonCountComparable(this.graduatedLessonCount, this.activeLessonCount);

  @override
  int compareTo(LessonCountComparable other) {
    if (graduatedLessonCount == other.graduatedLessonCount) {
      return activeLessonCount.compareTo(other.activeLessonCount);
    } else {
      return graduatedLessonCount.compareTo(other.graduatedLessonCount);
    }
  }
}
