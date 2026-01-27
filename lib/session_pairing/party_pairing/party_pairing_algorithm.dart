import 'package:flutter/material.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/session_pairing/party_pairing/pairing_unit.dart';
import 'package:social_learning/session_pairing/party_pairing/pairing_unit_set.dart';
import 'package:social_learning/session_pairing/party_pairing/party_pairing_context.dart';
import 'package:social_learning/session_pairing/party_pairing/scored_participant.dart';

class PartyPairingAlgorithm {
  final int unitSize;

  PairingUnitSet? candidatePairingUnitSet;
  Map<String, PairingUnitSet> _uniqueToPairingUnitSet = {};

  PartyPairingAlgorithm(this.unitSize);

  PairingUnitSet? pairAvailableStudents(BuildContext context) {
    PartyPairingContext pairingContext = PartyPairingContext(context);

    if (pairingContext.unpairedScoredParticipants.length < unitSize) {
      return null;
    }

    // Create the initial PairingUnitSet.
    PairingUnitSet initialPairingUnitSet =
        _createInitialPairingCandidate(pairingContext);
    _uniqueToPairingUnitSet[initialPairingUnitSet.createUniqueString()] =
        initialPairingUnitSet;
    candidatePairingUnitSet = initialPairingUnitSet;

    // TODO: Try other pairings.
  }

  PairingUnitSet _createInitialPairingCandidate(
      // TODO: Ensure that only groups of 2 or 3 are formed.
      PartyPairingContext pairingContext) {
    List<ScoredParticipant> unpairedParticipants =
        List.of(pairingContext.mostConstrainedParticipantsFirst);
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
      ScoredParticipant? mentorCandidate =
          _findAndRemoveMentor(leftOverParticipants, lesson) ??
              _findAndRemoveMentor(unpairedParticipants, lesson);

      // Couldn't find a mentor.
      if (mentorCandidate == null) {
        leftOverParticipants.add(learnerCandidate);
        continue;
      }

      // Find additional learners.
      List<ScoredParticipant> learnerCandidates = [learnerCandidate];
      _findAndRemoveAdditionalLearners(
          leftOverParticipants, lesson, learnerCandidates);
      _findAndRemoveAdditionalLearners(
          unpairedParticipants, lesson, learnerCandidates);

      // Create the PairingUnit.
      pairingUnits.add(PairingUnit(mentorCandidate, learnerCandidates, lesson, pairingContext));
    }

    return PairingUnitSet(pairingUnits, leftOverParticipants);
  }

  ScoredParticipant? _findAndRemoveMentor(
      List<ScoredParticipant> participants, Lesson lessonCandidate) {
    for (ScoredParticipant participant in participants) {
      if (participant.graduatedLessons.contains(lessonCandidate)) {
        participants.remove(participant);
        return participant;
      }
    }
    return null;
  }

  void _findAndRemoveAdditionalLearners(List<ScoredParticipant> participants,
      Lesson lessonCandidate, List<ScoredParticipant> learnerCandidates) {
    int i = 0;

    while (i < participants.length && learnerCandidates.length + 1 < unitSize) {
      final participant = participants[i];

      if (participant.prioritizedLessons.contains(lessonCandidate)) {
        participants.removeAt(i);
        learnerCandidates.add(participant);
        // do NOT increment i — next element shifts into this index
      } else {
        i++;
      }
    }
  }
}
