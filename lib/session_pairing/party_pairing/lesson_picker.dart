import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/session_pairing/party_pairing/pairing_unit.dart';
import 'package:social_learning/session_pairing/party_pairing/party_pairing_context.dart';
import 'package:social_learning/session_pairing/party_pairing/scored_participant.dart';
import 'package:social_learning/util/list_util.dart';

class LessonPicker {
  /// Returns the best lesson to run as a group session (or null if none is feasible).
  ///
  /// Rules:
  /// - Teachability: only if at least one student has the lesson in graduatedLessons.
  /// - Participation legality for each student: lesson must be in prioritizedLessons
  ///   OR in (graduatedLessons ∪ learnedLessonsInCurrentSession).
  /// - No all-review sessions: at least one student must have it in prioritizedLessons.
  /// - Preference: maximize learnCount; tie-break by minimizing worstRank, then sumRank.
  ///
  /// Heuristic probe:
  /// - Sort students by graduated count (desc).
  /// - Probe ALL prioritized lessons of the "frontier" student (2nd most graduated),
  ///   and (optionally) ALL prioritized lessons of the least graduated student.
  /// - If we find a perfect lesson (everyone learns it and it's rank-0 for everyone), return immediately.
  ///
  /// Note:
  /// - Uses Lesson equality (==) for membership. Ensure Lesson implements == and hashCode.
  /// - If your Lesson objects are not canonical, switch to using a stable key like lesson.id.
  static PairingUnit? chooseBestGroupLesson(
    List<ScoredParticipant> participants,
    PartyPairingContext pairingContext, {
    bool useProbeHeuristic = true,
    bool alsoProbeLeastGraduated = true,
  }) {
    final k = participants.length;
    if (k == 0) return null;

    // ----- Step 0: Precompute per-student lookup tables -----

    // prioritized rank: lesson -> index
    final prioRank = List<Map<Lesson, int>>.generate(k, (i) {
      final map = <Lesson, int>{};
      final prio = participants[i].prioritizedLessons;
      for (int idx = 0; idx < prio.length; idx++) {
        map.putIfAbsent(prio[idx], () => idx); // keep earliest occurrence
      }
      return map;
    }, growable: false);

    // review set: graduated ∪ learnedInCurrentSession
    final reviewSet = List<Set<Lesson>>.generate(k, (i) {
      final s = <Lesson>{};
      s.addAll(participants[i].graduatedLessons);
      s.addAll(participants[i].learnedLessonsInCurrentSession);
      return s;
    }, growable: false);

    // ----- Step 1: Build teachable candidates (only graduatedLessons can teach) -----

    final teachersByLesson = <Lesson, List<int>>{};
    for (int si = 0; si < k; si++) {
      for (final lesson in participants[si].graduatedLessons) {
        (teachersByLesson[lesson] ??= <int>[]).add(si);
      }
    }
    if (teachersByLesson.isEmpty) return null;

    _LessonChoice? evaluateLesson(Lesson lesson) {
      final teachers = teachersByLesson[lesson];
      if (teachers == null || teachers.isEmpty) return null; // not teachable

      final learners = <int>[];
      final reviewers = <int>[];

      int learnCount = 0;
      int worstRank = 0;
      int sumRank = 0;

      for (int si = 0; si < k; si++) {
        final r = prioRank[si][lesson];
        if (r != null) {
          learnCount++;
          learners.add(si);
          if (r > worstRank) worstRank = r;
          sumRank += r;
        } else if (reviewSet[si].contains(lesson)) {
          reviewers.add(si);
        } else {
          return null; // illegal for this student
        }
      }

      if (learnCount == 0) return null; // no all-review sessions

      return _LessonChoice(
        lesson: lesson,
        teacherIndices: List<int>.unmodifiable(teachers),
        learnerIndices: List<int>.unmodifiable(learners),
        reviewerIndices: List<int>.unmodifiable(reviewers),
        learnCount: learnCount,
        worstRank: worstRank,
        sumRank: sumRank,
      );
    }

    bool isPerfect(_LessonChoice c) => c.learnCount == k && c.worstRank == 0;

    bool better(_LessonChoice a, _LessonChoice b) {
      if (a.learnCount != b.learnCount) {
        return a.learnCount > b.learnCount; // maximize learners
      }
      if (a.worstRank != b.worstRank) {
        return a.worstRank < b.worstRank; // fairness
      }
      if (a.sumRank != b.sumRank) {
        return a.sumRank < b.sumRank; // overall priority
      }
      if (a.teacherIndices.length != b.teacherIndices.length) {
        return a.teacherIndices.length > b.teacherIndices.length; // flexibility
      }
      return false;
    }

    // ----- Step 2: Probe heuristic (optional), using ENTIRE prioritized list -----
    if (useProbeHeuristic && k >= 2) {
      final indicesByGrad = List<int>.generate(k, (i) => i)
        ..sort(
          (a, b) => participants[b].graduatedLessons.length.compareTo(
            participants[a].graduatedLessons.length,
          ),
        );

      // 2nd most graduated = "frontier" (your heuristic)
      final frontierIdx = indicesByGrad[1];
      for (final lesson in participants[frontierIdx].prioritizedLessons) {
        final c = evaluateLesson(lesson);
        if (c == null) continue;
        if (isPerfect(c)) return c.toPairingUnit(participants, pairingContext);
      }

      if (alsoProbeLeastGraduated) {
        final leastIdx = indicesByGrad.last;
        for (final lesson in participants[leastIdx].prioritizedLessons) {
          final c = evaluateLesson(lesson);
          if (c == null) continue;
          if (isPerfect(c)) return c.toPairingUnit(participants, pairingContext);
        }
      }
    }

    // ----- Step 3: Full evaluation over all teachables (early exit if perfect) -----

    _LessonChoice? bestChoice;

    for (final lesson in teachersByLesson.keys) {
      final c = evaluateLesson(lesson);
      if (c == null) continue;

      if (isPerfect(c)) return c.toPairingUnit(participants, pairingContext);

      if (bestChoice == null || better(c, bestChoice)) {
        bestChoice = c;
      }
    }

    return bestChoice?.toPairingUnit(participants, pairingContext);
  }
}

class _LessonChoice {
  final Lesson lesson;
  final List<int> teacherIndices; // indices into participants
  final List<int> learnerIndices; // prioritized
  final List<int>
  reviewerIndices; // graduated or learnedInSession (and not prioritized)
  final int learnCount;
  final int worstRank; // max index among learners in prioritized list
  final int sumRank;

  const _LessonChoice({
    required this.lesson,
    required this.teacherIndices,
    required this.learnerIndices,
    required this.reviewerIndices,
    required this.learnCount,
    required this.worstRank,
    required this.sumRank,
  });

  PairingUnit toPairingUnit(
    List<ScoredParticipant> participants,
    PartyPairingContext pairingContext,
  ) {
    ScoredParticipant mentor = participants[teacherIndices[0]];

    List<ScoredParticipant> learners = (learnerIndices)
        .minus([teacherIndices[0]])
        .map((i) => participants[i])
        .toList();
    return PairingUnit(mentor, learners, lesson, pairingContext);
  }

  @override
  String toString() =>
      'LessonChoice(lesson=$lesson, learnCount=$learnCount, worstRank=$worstRank, sumRank=$sumRank, teachers=$teacherIndices)';
}
