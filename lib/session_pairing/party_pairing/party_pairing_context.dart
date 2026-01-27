import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/session_pairing.dart';
import 'package:social_learning/data/session_participant.dart';
import 'package:social_learning/session_pairing/party_pairing/scored_participant.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/organizer_session_state.dart';

import 'package:social_learning/data/user.dart';

class PartyPairingContext {
  final ApplicationState applicationState;
  final LibraryState libraryState;
  final OrganizerSessionState organizerSessionState;

  late List<ScoredParticipant> unpairedScoredParticipants;
  late List<ScoredParticipant> mostConstrainedParticipantsFirst;
  final Map<Lesson, int> lessonsToFrequency = {};
  final Map<int, List<Lesson>> frequenciesToLesson = {};

  PartyPairingContext(BuildContext context)
      : applicationState = context.read<ApplicationState>(),
        libraryState = context.read<LibraryState>(),
        organizerSessionState = context.read<OrganizerSessionState>() {
    _initUnpairedParticipants();
    _initMostConstrainedParticipantsFirst();
    _initLessonFrequency();
  }

  void _initUnpairedParticipants() {
    List<SessionParticipant> allParticipants =
        organizerSessionState.sessionParticipants;

    // Remove the session host if configured.
    if (organizerSessionState.currentSession?.includeHostInPairing ?? false) {
      User hostUser = applicationState.currentUser!;
      allParticipants.removeWhere(
          (participant) => participant.participantId.id == hostUser.id);
    }

    Iterable<SessionPairing> activePairings = organizerSessionState.allPairings
        .where((pairing) => !pairing.isCompleted);
    Set<SessionParticipant> unpairedParticipants = {...allParticipants};

    for (SessionPairing pairing in activePairings) {
      if (pairing.mentorId != null) {
        unpairedParticipants.removeWhere(
            (participant) => participant.participantId == pairing.mentorId);
      }

      if (pairing.menteeId != null) {
        unpairedParticipants.removeWhere(
            (participant) => participant.participantId == pairing.menteeId);
      }

      for (DocumentReference additionalStudent
          in pairing.additionalStudentIds) {
        unpairedParticipants.removeWhere(
            (participant) => participant.participantId == additionalStudent);
      }
    }

    unpairedScoredParticipants = unpairedParticipants
        .map((participant) => ScoredParticipant(participant, this))
        .toList();
  }

  void _initMostConstrainedParticipantsFirst() {
    Map<ScoredParticipant, int> constraintCountByParticipant = {};
    for (ScoredParticipant participant in unpairedScoredParticipants!) {
      if (participant.prioritizedLessons.isEmpty) {
        constraintCountByParticipant[participant] = 0;
        continue;
      }

      int potentialMentorCount = 0;
      Lesson lesson = participant.prioritizedLessons.first;

      for (ScoredParticipant otherParticipant in unpairedScoredParticipants!) {
        if (otherParticipant == participant) {
          continue;
        }

        if (otherParticipant.graduatedLessons.contains(lesson)) {
          potentialMentorCount++;
        }
      }

      constraintCountByParticipant[participant] = potentialMentorCount;
    }

    // Sort and convert to a list of participants.
    // The host is always last by convention because the host doesn't want to
    // learn.
    List<MapEntry<ScoredParticipant, int>> sortedEntries =
        constraintCountByParticipant.entries.toList()
          ..sort((a, b) {
            if (a.key.isHost) return 1;
            if (b.key.isHost) return -1;

            return a.value.compareTo(b.value);
          });

    mostConstrainedParticipantsFirst =
        sortedEntries.map((entry) => entry.key).toList();
  }

  void _initLessonFrequency() {
    // Initialize all lessons to make sure to get zero count lessons.
    for (Lesson lesson in libraryState.lessons!) {
      lessonsToFrequency[lesson] = 0;
    };

    // Add how often lessons are known among participants.
    for (ScoredParticipant participant in unpairedScoredParticipants) {
      for (Lesson lesson in participant.graduatedLessons) {
        lessonsToFrequency[lesson] = (lessonsToFrequency[lesson] ?? 0) + 1;
      }
    }

    // Flip to frequenciesToLesson.
    for (MapEntry<Lesson, int> entry in lessonsToFrequency.entries) {
      int frequency = entry.value;
      Lesson lesson = entry.key;
      frequenciesToLesson.putIfAbsent(frequency, () => []).add(lesson);
    }
  }
}
