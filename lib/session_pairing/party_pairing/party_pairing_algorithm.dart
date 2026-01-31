import 'package:flutter/material.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/session_pairing/party_pairing/pairing_scorer.dart';
import 'package:social_learning/session_pairing/party_pairing/pairing_unit.dart';
import 'package:social_learning/session_pairing/party_pairing/pairing_unit_set.dart';
import 'package:social_learning/session_pairing/party_pairing/party_pairing_context.dart';
import 'package:social_learning/session_pairing/party_pairing/scored_participant.dart';
import 'package:social_learning/util/list_util.dart';

import 'lesson_picker.dart';

class PartyPairingAlgorithm {
  final int unitSize;

  PairingUnitSet? candidatePairingUnitSet;
  final Map<String, PairingUnitSet> _uniqueToPairingUnitSet = {};

  PartyPairingAlgorithm(this.unitSize);

  PairingUnitSet? pairAvailableStudents(BuildContext context) {
    Stopwatch stopwatch = Stopwatch()..start();
    PartyPairingContext pairingContext = PartyPairingContext(context);

    if (pairingContext.unpairedScoredParticipants.length < unitSize) {
      return null;
    }

    // Create the initial PairingUnitSet.
    PairingUnitSet initialPairingUnitSet = _createInitialPairingCandidate(
      pairingContext,
    );
    _uniqueToPairingUnitSet[initialPairingUnitSet.createUniqueString()] =
        initialPairingUnitSet;
    candidatePairingUnitSet = initialPairingUnitSet;

    // Try other pairings by breaking two units and recombining them.
    PairingUnitSet lastCandidate = candidatePairingUnitSet!;
    do {
      lastCandidate = candidatePairingUnitSet!;
      breakAndRepair(candidatePairingUnitSet!, 2, pairingContext);
    } while (candidatePairingUnitSet != lastCandidate);

    stopwatch.stop();
    print('Pairing algorithm took ${stopwatch.elapsed}');

    return candidatePairingUnitSet;
  }

  PairingUnitSet _createInitialPairingCandidate(
    PartyPairingContext pairingContext,
  ) {
    List<ScoredParticipant> unpairedParticipants = List.of(
      pairingContext.mostConstrainedParticipantsFirst,
    );
    List<ScoredParticipant> leftOverParticipants = [];
    List<PairingUnit> pairingUnits = [];

    while (unpairedParticipants.isNotEmpty) {
      ScoredParticipant learnerCandidate = unpairedParticipants.removeAt(0);

      // Skip the host because the host doesn't learn.
      if (learnerCandidate.isHost) {
        leftOverParticipants.add(learnerCandidate);
        continue;
      }

      // Handle the case if a learner has no lesson left to learn.
      if (learnerCandidate.prioritizedLessons.isEmpty) {
        leftOverParticipants.add(learnerCandidate);
        continue;
      }

      // Find a mentor.
      Lesson lesson = learnerCandidate.prioritizedLessons.first;
      List<ScoredParticipant> combinedParticipantPool = [
        ...leftOverParticipants,
        ...unpairedParticipants,
      ];
      ScoredParticipant? mentorCandidate = _findMentor(
        combinedParticipantPool,
        lesson,
      );

      // Couldn't find a mentor.
      if (mentorCandidate == null) {
        leftOverParticipants.add(learnerCandidate);
        continue;
      }

      // Find additional learners.
      List<ScoredParticipant> learnerCandidates = [
        learnerCandidate,
        ..._findAdditionalLearners(combinedParticipantPool, lesson),
      ];

      // Create the PairingUnit.
      if (learnerCandidates.length + 1 /* mentor */ == unitSize) {
        // Remove the mentor and additional learners from the students
        // available for pairing.
        unpairedParticipants.remove(mentorCandidate);
        leftOverParticipants.remove(mentorCandidate);
        unpairedParticipants.removeWhere((p) => learnerCandidates.contains(p));
        leftOverParticipants.removeWhere((p) => learnerCandidates.contains(p));

        pairingUnits.add(
          PairingUnit(
            mentorCandidate,
            learnerCandidates,
            lesson,
            pairingContext,
          ),
        );
      } else {
        // Couldn't find enough additional learners to meet the unit size.
        // We'll try to do desperate pairings later.
        leftOverParticipants.add(learnerCandidate);
      }
    }

    // Use the left over participants to create any kind of pairing that get
    // a student to progress. We assume that the trio size or whatever the unit
    // size is has to be reached. E.g., in acroyoga we need three people
    // (a flyer, base, and a spotter).
    pairingUnits.addAll(
      createDesperatePairings(leftOverParticipants, pairingContext),
    );

    return PairingUnitSet(pairingUnits, leftOverParticipants);
  }

  ScoredParticipant? _findMentor(
    List<ScoredParticipant> participants,
    Lesson lessonCandidate,
  ) {
    for (ScoredParticipant participant in participants) {
      if (participant.graduatedLessons.contains(lessonCandidate)) {
        // participants.remove(participant);
        return participant;
      }
    }
    return null;
  }

  List<ScoredParticipant> _findAdditionalLearners(
    List<ScoredParticipant> participants,
    Lesson lessonCandidate,
  ) {
    List<ScoredParticipant> learnerCandidates = [];
    int i = 0;

    while (i < participants.length &&
        learnerCandidates.length + 1 /* initial learner */ + 1 /* mentor */ <
            unitSize) {
      final participant = participants[i];

      if (participant.prioritizedLessons.contains(lessonCandidate)) {
        // participants.removeAt(i);
        learnerCandidates.add(participant);
        // do NOT increment i — next element shifts into this index
      } else {
        i++;
      }
    }

    return learnerCandidates;
  }

  /// Create desperate pairings. There may be some students left unpaired after
  /// any good pairings have been found. We'll try to pair them because doing
  /// something is better than nothing. Specifically, we may have cases where
  /// a mentor could teach a single student a lesson. However, there aren't
  /// enough learners to create a trio. So we look for someone who could repeat
  /// the lesson simply for practice.
  List<PairingUnit> createDesperatePairings(
    List<ScoredParticipant> leftOverParticipants,
    PartyPairingContext pairingContext,
  ) {
    // Start with participants who have already learned the most because they
    // are hardest to pair.
    leftOverParticipants.sort(
      (a, b) => b.graduatedLessons.length.compareTo(a.graduatedLessons.length),
    );

    List<ScoredParticipant> hardLeftOverParticipants = [];
    List<PairingUnit> pairings = [];
    nextLearnerCandidate:
    while (leftOverParticipants.isNotEmpty &&
        (leftOverParticipants.length + hardLeftOverParticipants.length >
            unitSize)) {
      ScoredParticipant learnerCandidate = leftOverParticipants.removeAt(0);

      // Try for each prioritized lesson.
      for (Lesson lessonCandidate in learnerCandidate.prioritizedLessons) {
        // Find a mentor.
        var combinedParticipants = [
          ...hardLeftOverParticipants,
          ...leftOverParticipants,
        ];
        for (ScoredParticipant mentorCandidate in combinedParticipants) {
          if (!mentorCandidate.graduatedLessons.contains(lessonCandidate)) {
            continue;
          }

          List<ScoredParticipant> additionalLearnerCandidates = [];
          for (ScoredParticipant additionalLearnerCandidate
              in combinedParticipants) {
            if (additionalLearnerCandidates.length +
                    1 /* mentor candidate */ +
                    1 /* learner candidate */ ==
                unitSize) {
              break;
            }

            if (additionalLearnerCandidate == mentorCandidate) {
              continue;
            }

            if (additionalLearnerCandidate.prioritizedLessons.contains(
                  lessonCandidate,
                ) ||
                additionalLearnerCandidate.graduatedLessons.contains(
                  lessonCandidate,
                )) {
              additionalLearnerCandidates.add(additionalLearnerCandidate);
            }
          }

          // If we have enough students, create a pairing unit.
          if (additionalLearnerCandidates.length +
                  1 /* mentor candidate */ +
                  1 /* learner candidate */ ==
              unitSize) {
            pairings.add(
              PairingUnit(
                mentorCandidate,
                [learnerCandidate, ...additionalLearnerCandidates],
                lessonCandidate,
                pairingContext,
              ),
            );

            // Remove the mentor and learning candidates from the list of
            // available students.
            leftOverParticipants.remove(mentorCandidate);
            hardLeftOverParticipants.remove(mentorCandidate);
            leftOverParticipants.removeWhere(
              (p) => additionalLearnerCandidates.contains(p),
            );
            hardLeftOverParticipants.removeWhere(
              (p) => additionalLearnerCandidates.contains(p),
            );
            continue nextLearnerCandidate;
          }
        }
      }

      hardLeftOverParticipants.add(learnerCandidate);
    }

    return pairings;
  }

  /// Takes a set of pairings and breaks n pairings to see in how many ways
  /// it can recombine the available students.
  void breakAndRepair(
    PairingUnitSet originalSet,
    int breakCount,
    PartyPairingContext pairingContext,
  ) {
    if (originalSet.pairingUnits.length < breakCount) {
      return;
    }

    originalSet.pairingUnits.forEachCombination(breakCount, (brokenUnits) {
      List<PairingUnitSet> newSets = breakAndRepairTuples(
        originalSet,
        brokenUnits,
        pairingContext,
      );

      // Evaluate new sets.
      for (PairingUnitSet newSet in newSets) {
        _uniqueToPairingUnitSet[newSet.createUniqueString()] = newSet;

        PairingScorer.score(candidatePairingUnitSet!.score, newSet.score);

        if ((newSet.score.totalScore ?? 0) >
            (candidatePairingUnitSet!.score.totalScore ?? 0)) {
          candidatePairingUnitSet = newSet;
        }
      }
    });
  }

  List<PairingUnitSet> breakAndRepairTuples(
    PairingUnitSet originalSet,
    List<PairingUnit> brokenUnits,
    PartyPairingContext pairingContext,
  ) {
    // Prepare.
    List<PairingUnit> basePairingUnits = originalSet.pairingUnits.minus(
      brokenUnits,
    );
    List<ScoredParticipant> availableParticipants =
        brokenUnits.expand((u) => [u.mentor, ...u.learners]).toSet().toList()
          ..addAll(originalSet.leftOverParticipants);

    // Evaluate every possible recombination.
    List<PairingUnitSet> resultSets = [];
    availableParticipants.forEachMaxGroupings(unitSize, (
      listOfListOfParticipants,
      newLeftOvers,
    ) {
      // Create the new PairingUnitSet.
      List<PairingUnit> newlyFormedUnits = listOfListOfParticipants
          .map(
            (participants) => LessonPicker.chooseBestGroupLesson(
              participants,
              pairingContext,
            ),
          )
          .whereType<PairingUnit>()
          .toList();
      PairingUnitSet newSet = PairingUnitSet([
        ...basePairingUnits,
        ...newlyFormedUnits,
      ], newLeftOvers);

      // Skip already evaluated sets.
      var uniqueString = newSet.createUniqueString();
      if (!_uniqueToPairingUnitSet.containsKey(uniqueString)) {
        _uniqueToPairingUnitSet[uniqueString] = newSet;
        resultSets.add(newSet);
      }

      // // Evaluate the new PairingUnitSet.
      // PairingScorer.score(candidatePairingUnitSet!.score, newSet.score);
      // if ((newSet.score.totalScore ?? 0) >
      //     (candidatePairingUnitSet?.score.totalScore ?? 0)) {
      //   candidatePairingUnitSet = newSet;
      // }
    });

    return resultSets;
  }
}
