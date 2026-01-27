import 'package:flutter/material.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/practice_record.dart';
import 'package:social_learning/data/session_pairing.dart';
import 'package:social_learning/data/session_participant.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/session_pairing/party_pairing/pairing_score.dart';
import 'package:social_learning/session_pairing/party_pairing/party_pairing_context.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/organizer_session_state.dart';

import 'package:social_learning/data/session.dart';

class ScoredParticipant {
  static const int maxPrioritizedLessons = 5;

  final PartyPairingContext pairingContext;

  final User user;
  late final bool isHost;
  late final double learnCount;
  late final int teachCount;
  late final double teachingDeficit; // teachCount - learnCount
  final SessionParticipant participant;
  List<PracticeRecord> learnPracticeRecords = [];
  List<PracticeRecord> teachPracticeRecords = [];
  late final List<Lesson> graduatedLessons;
  late final List<Lesson> learnedLessonsInCurrentSession;
  late final List<Lesson> prioritizedLessons;

  ScoredParticipant(this.participant, this.pairingContext)
      : user = pairingContext.organizerSessionState.getUser(participant)! {
    _initIsHost();
    _initPracticeRecords();
    _initGraduatedLessons();
    _initLearnedLessonsInCurrentSession();
    _initPrioritizedLessons();
    _initLearnTeachCounts();
  }

  void _initIsHost() {
    isHost = pairingContext.applicationState.currentUser?.uid == user.uid;
  }

  void _initPracticeRecords() {
    for (PracticeRecord practiceRecord
    in pairingContext.organizerSessionState.practiceRecords) {
      if (practiceRecord.menteeUid == participant.participantUid) {
        learnPracticeRecords.add(practiceRecord);
      } else if (practiceRecord.mentorUid == participant.participantUid) {
        teachPracticeRecords.add(practiceRecord);
      }
    }
  }

  void _initGraduatedLessons() {
    graduatedLessons =
        pairingContext.organizerSessionState.getGraduatedLessons(participant);
  }

  void _initLearnedLessonsInCurrentSession() {
    Session session = pairingContext.organizerSessionState.currentSession!;

    for (PracticeRecord practiceRecord in learnPracticeRecords) {
      if (practiceRecord.timestamp != null &&
          practiceRecord.timestamp!
              .toDate()
              .isAfter(session.startTime!.toDate())) {
        Lesson? lesson =
        pairingContext.libraryState.findLesson(practiceRecord.lessonId.id);
        if (lesson != null) {
          learnedLessonsInCurrentSession.add(lesson);
        }
      }
    }
  }

  void _initPrioritizedLessons() {
    List<Lesson>? allLessons = pairingContext.libraryState.lessons;

    if (allLessons != null) {
      for (Lesson lesson in allLessons) {
        if (prioritizedLessons.length >= maxPrioritizedLessons) {
          return;
        }

        if (graduatedLessons.contains(lesson) &&
            learnedLessonsInCurrentSession.contains(lesson)) {
          continue;
        }

        prioritizedLessons.add(lesson);
      }
    }
  }

  void _initLearnTeachCounts() {
    for (SessionPairing pairing in pairingContext.organizerSessionState
        .allPairings) {
      if (!pairing.isCompleted) {
        continue;
      }

      if (pairing.mentorId == participant.participantId) {
        teachCount++;
        teachingDeficit++;
      }
      if (pairing.menteeId == participant.participantId ||
          pairing.additionalStudentIds.contains(participant.participantId)) {
        int learnerCount = 0;
        if (pairing.menteeId != null) {
          learnerCount++;
        }
        learnerCount += pairing.additionalStudentIds.length;
        teachingDeficit -= 1 / learnerCount;
        learnCount++;
      }
    }
  }

  void computeRawScore(PairingScore score) {
    score.addRawScore(.diversePartners, _countPartners());
    if (!isHost) {
      score.addRawScore(.balanceHostAccess, _countHostAccess());
    }
    score.addRawScore(.reduceTeachingDeficit, teachingDeficit);
  }

  double _countPartners() {
    Set<String> partnerUserIds = {};
    for (SessionPairing pairing in pairingContext.organizerSessionState
        .allPairings) {
      if (pairing.mentorId == participant.participantId ||
          pairing.menteeId == participant.participantId ||
          pairing.additionalStudentIds.contains(participant.participantId)) {
        if (pairing.mentorId != null) {
          partnerUserIds.add(pairing.mentorId!.id);
        }

        if (pairing.menteeId != null) {
          partnerUserIds.add(pairing.menteeId!.id);
        }

        if (pairing.additionalStudentIds.isNotEmpty) {
          partnerUserIds.addAll(
              pairing.additionalStudentIds.map((docRef) => docRef.id));
        }
      }
    }

    // Remove self.
    partnerUserIds.remove(user.id);

    return partnerUserIds.length.toDouble();
  }

  double _countHostAccess() {
    String? hostUserId = pairingContext.applicationState.currentUser?.id;
    if (hostUserId == null) {
      return 0;
    }

    int hostAccessCount = 0;

    for (SessionPairing pairing in pairingContext.organizerSessionState
        .allPairings) {
      if (pairing.mentorId == participant.participantId ||
          pairing.menteeId == participant.participantId ||
          pairing.additionalStudentIds.contains(participant.participantId)) {
        if (pairing.mentorId != null && pairing.mentorId!.id == hostUserId) {
          hostAccessCount++;
        } else
        if (pairing.menteeId != null && pairing.menteeId!.id == hostUserId) {
          hostAccessCount++;
        } else if (pairing.additionalStudentIds.isNotEmpty &&
            pairing.additionalStudentIds.any((docRef) =>
            docRef.id ==
                hostUserId)) {
          hostAccessCount++;
        }
      }
    }

    return hostAccessCount.toDouble();
  }
}