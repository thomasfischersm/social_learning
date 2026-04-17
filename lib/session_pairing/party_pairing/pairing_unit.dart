import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/session_pairing/party_pairing/pairing_score.dart';
import 'package:social_learning/session_pairing/party_pairing/party_pairing_context.dart';
import 'package:social_learning/session_pairing/party_pairing/scored_participant.dart';
import 'package:social_learning/state/organizer_session_state.dart';

import 'package:social_learning/data/Level.dart';

class PairingUnit {
  /// How many times a rare lesson can be known for it to count rare.
  static const int _rareLessonFactor = 3;

  /// Factor to make rarer lessons more meaningful in the score.
  static const int _rareLessonScoreFactor = 10;

  final PartyPairingContext pairingContext;
  final ScoredParticipant mentor;
  final List<ScoredParticipant> learners;
  Lesson lesson;

  PairingUnit(this.mentor, this.learners, this.lesson, this.pairingContext);

  String createUniqueString() {
    StringBuffer str = StringBuffer();

    // Add mentor.
    str.write(mentor.participant.participantId.id);
    str.write(':');

    // Sort learners
    List<ScoredParticipant> sortedLearners = List.of(learners)
      ..sort((a, b) =>
          a.participant.participantId.id
              .compareTo(b.participant.participantId.id));

    // Add learners.
    for (ScoredParticipant learner in sortedLearners) {
      str.write(learner.participant.participantId.id);
      if (learner != learners.last) {
        str.write(',');
      }
    }

    // Add lesson.
    if (lesson != null) {
      str.write(':');
      str.write(lesson!.id);
    }

    return str.toString();
  }

  void computeRawScore(PairingScore score) {
    _computeFinishLevelBeforeMovingOn(score);
    _computeNearestLessonScore(score);
    _computeBalanceStudentDistance(score);
    _computeRareLessonScore(score);
    _computeNewLessonScore(score);

    for (ScoredParticipant participant in [mentor, ...learners]) {
      participant.computeRawScore(score, this);
    }
  }

  /// We prefer that students finish the current level before starting lessons
  /// from the next level. Thus, we look at the first preferred lesson of each
  /// student. If the lesson chosen by this pairing unit is in the next level,
  /// it is counted as a negative.
  void _computeFinishLevelBeforeMovingOn(PairingScore score) {
    int levelSkipCount = 0;
    int? levelIndex = _findLevelIndex(lesson);
    if (levelIndex == null) {
      return;
    }

    for (ScoredParticipant participant in [mentor, ...learners]) {
      if (participant.isHost || participant.prioritizedLessons.isEmpty) {
        continue;
      }

      int? participantLevelIndex = _findLevelIndex(
          participant.prioritizedLessons.first);
      if (participantLevelIndex == null) {
        continue;
      }

      if (levelIndex > participantLevelIndex) {
        levelSkipCount += levelIndex - participantLevelIndex;
      }
    }

    score.addRawScore(.finishLevelBeforeMovingOn, levelSkipCount.toDouble());
  }

  int? _findLevelIndex(Lesson lesson) {
    DocumentReference? levelId = lesson.levelId;
    if (levelId == null) {
      return null;
    }
    Level? unitLevel = pairingContext.libraryState.findLevel(levelId.id);
    if (unitLevel == null) {
      return null;
    }
    return pairingContext.libraryState.levels?.indexOf(unitLevel);
  }

  /// The pairing algorithm has flexibility to jump ahead to future lessons.
  /// This is done to make pairings possible even if they are not optimal. This
  /// score expresses the preference to focus on the next lesson rather than
  /// skipping lessons ahead.
  void _computeNearestLessonScore(PairingScore score) {
    double nearestLessonScore = 0;

    for (ScoredParticipant participant in [mentor, ...learners]) {
      if (participant.isHost) {
        continue;
      }

      var index = participant.prioritizedLessons.indexOf(lesson);
      if (index > 0) {
        nearestLessonScore += index;
      }
    }

    score.addRawScore(.learnNearestLesson, nearestLessonScore);
  }

  /// There may be multiple ways to pair up students. If the pairings are
  /// basically sound and everyone is paired, we prefer to have students working
  /// together who are closer to each others level.
  ///
  /// Example: Say that we have students A, B, C, and D. Their order reflects
  /// how far they are progressed. Student A and D are the furthest apart.
  /// Thus, we'd prefer to have student A/B and C/D to work together.
  void _computeBalanceStudentDistance(PairingScore score) {
    var lessons = pairingContext.libraryState.lessons;
    if (lessons == null || lessons.isEmpty) {
      return;
    }

    for (ScoredParticipant participant in [mentor, ...learners]) {
      if (participant.isHost) {
        continue;
      }

      if (participant.prioritizedLessons.isEmpty) {
        continue;
      }

      int lessonIndex = lessons.indexOf(participant.prioritizedLessons.first);
      if (lessonIndex == -1) {
        continue;
      }

      for (ScoredParticipant otherParticipant in [mentor, ...learners]) {
        if (otherParticipant.isHost || otherParticipant == participant) {
          continue;
        }

        if (otherParticipant.prioritizedLessons.isEmpty) {
          continue;
        }

        int otherLessonIndex = lessons.indexOf(
            otherParticipant.prioritizedLessons.first);
        if (otherLessonIndex == -1) {
          continue;
        }

        int distance = (lessonIndex - otherLessonIndex).abs();
        score.addRawScore(.balanceStudentDistance, distance.toDouble());
      }
    }
  }

  /// With creating pairings, an important factor is to look ahead to avoid
  /// creating bottlenecks. Let's say we have a large class and there is a
  /// lesson that only one student can teach. So we should start spreading that
  /// lesson to more students first before we have rounds where we can't pair
  /// some students.
  ///
  /// Because it's expensive to consider all the future permutations, we are
  /// using a heuristic. The less students know a certain lesson, the more that
  /// lesson gets prioritized.
  void _computeRareLessonScore(PairingScore score) {
    double rareLessonScore = 0;
    for (int i = 0; i < _rareLessonFactor; i++) {
      if (pairingContext.frequenciesToLesson[i]?.contains(lesson) ?? false) {
        rareLessonScore =  pow(_rareLessonScoreFactor, _rareLessonFactor - i - 1).toDouble();
        break;
      }
    }

    score.addRawScore(.prioritizeRareLessons, rareLessonScore);
  }

  /// Using desperate pairings, we may have cases were a student is only
  /// practicing a lesson. This score counts the number of lessons that students
  /// would graduate to focus the algorithm on making progress through the
  /// curriculum.
  void _computeNewLessonScore(PairingScore score) {
    double newLessonCount = 0;

    for (ScoredParticipant participant in learners) {
      if (participant.isHost) {
        continue;
      }

      if (!participant.graduatedLessons.contains(lesson)) {
        newLessonCount++;
      }
    }

    score.addRawScore(.learnNewLessonCount, newLessonCount);
  }
}
