import 'package:flutter/material.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/practice_record.dart';
import 'package:social_learning/data/session_pairing.dart';
import 'package:social_learning/data/session_participant.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/session_pairing/party_pairing/pairing_score.dart';
import 'package:social_learning/session_pairing/party_pairing/pairing_unit.dart';
import 'package:social_learning/session_pairing/party_pairing/party_pairing_context.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/organizer_session_state.dart';

import 'package:social_learning/data/session.dart';
import 'package:social_learning/util/print_util.dart';

class ScoredParticipant {
  static const int maxPrioritizedLessons = 5;

  final PartyPairingContext pairingContext;

  final User user;
  late final bool isHost;
  late final double learnCount;
  late final double teachCount;
  late final double teachingDeficit; // teachCount - learnCount
  final SessionParticipant participant;
  List<PracticeRecord> learnPracticeRecords = [];
  List<PracticeRecord> teachPracticeRecords = [];
  late final Set<Lesson> graduatedLessons;
  final Set<Lesson> learnedLessonsInCurrentSession = {};
  final List<Lesson> prioritizedLessons = [];

  ScoredParticipant(this.participant, this.pairingContext)
    : user = pairingContext.organizerSessionState.getUser(participant)! {
    dprint('Initializing scored participant ${user.displayName}');
    _initIsHost();
    _initPracticeRecords();
    _initGraduatedLessons();
    _initLearnedLessonsInCurrentSession();
    _initPrioritizedLessons();
    _initLearnTeachCounts();
    dprint('Finished initializing scored participant ${user.displayName}');
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
    graduatedLessons = pairingContext.organizerSessionState
        .getGraduatedLessons(participant)
        .toSet();
    dprint(
      'Initializing graduated lessons for ${user.displayName} with ${graduatedLessons.length} lessons:',
    );
  }

  void _initLearnedLessonsInCurrentSession() {
    Session session = pairingContext.organizerSessionState.currentSession!;

    for (PracticeRecord practiceRecord in learnPracticeRecords) {
      if (practiceRecord.timestamp != null &&
          practiceRecord.timestamp!.toDate().isAfter(
            session.startTime!.toDate(),
          )) {
        Lesson? lesson = pairingContext.libraryState.findLesson(
          practiceRecord.lessonId.id,
        );
        if (lesson != null) {
          learnedLessonsInCurrentSession.add(lesson);
        }
      }
    }

    dprint('learned lessons for ${user.displayName} are:');
    for (Lesson lesson in learnedLessonsInCurrentSession) {
      dprint('- ${lesson.title}');
    }
  }

  void _initPrioritizedLessons() {
    try {
      List<Lesson>? allLessons = pairingContext.libraryState.lessons;

      if (allLessons != null) {
        for (Lesson lesson in allLessons) {
          if (prioritizedLessons.length >= maxPrioritizedLessons) {
            return;
          }

          if (graduatedLessons.contains(lesson) ||
              learnedLessonsInCurrentSession.contains(lesson)) {
            continue;
          }

          prioritizedLessons.add(lesson);
        }
      }
    } finally {
      dprint('Prioritized lessons for ${user.displayName}:');
      for (Lesson lesson in prioritizedLessons) {
        dprint('- ${lesson.title}');
      }
    }
  }

  void _initLearnTeachCounts() {
    double teachCount = 0;
    double learnCount = 0;
    double teachingDeficit = 0;

    for (SessionPairing pairing
        in pairingContext.organizerSessionState.allPairings) {
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

    this.teachCount = teachCount;
    this.learnCount = learnCount;
    this.teachingDeficit = teachingDeficit;
  }

  void computeRawScore(PairingScore score, PairingUnit? pairingUnit) {
    score.addRawScore(.diversePartners, _countPartners(pairingUnit));

    if (!isHost) {
      score.addRawScore(.balanceHostAccess, _countHostAccess(pairingUnit));

      score.addRawScore(
            .reduceTeachingDeficit,
        _computeTeachingDeficitScore(pairingUnit),
      );

      score.addRawScore(
            .equalizeParticipation,
        _computeEqualizeParticipation(pairingUnit),
      );

      score.addRawScore(
            .minimizePracticing,
        _computeMinimizePracticing(pairingUnit),
      );
    }
  }

  /// The goal is to have students partner with as many students as possible.
  /// The reason is that this exposes students to more variety of people
  /// and teaching styles. Plus, it equalizes access to desirable and
  /// undesirable students.
  double _countPartners(PairingUnit? pairingUnit) {
    Set<String> partnerUserIds = {};
    for (SessionPairing pairing
        in pairingContext.organizerSessionState.allPairings) {
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
            pairing.additionalStudentIds.map((docRef) => docRef.id),
          );
        }
      }
    }

    // Add the current pairings partners.
    if (pairingUnit != null) {
      partnerUserIds.add(pairingUnit.mentor.user.id);
      for (ScoredParticipant learner in pairingUnit.learners) {
        partnerUserIds.add(learner.user.id);
      }
    }

    // Remove self.
    partnerUserIds.remove(user.id);

    return partnerUserIds.length.toDouble();
  }

  /// Getting access to learn directly from the host is desirable. This score
  /// helps equalize access to the host.
  double _countHostAccess(PairingUnit? pairingUnit) {
    if (isHost) {
      return 0;
    }

    String? hostUserId = pairingContext.applicationState.currentUser?.id;
    if (hostUserId == null) {
      return 0;
    }

    int hostAccessCount = 0;

    for (SessionPairing pairing
        in pairingContext.organizerSessionState.allPairings) {
      if (pairing.mentorId == participant.participantId ||
          pairing.menteeId == participant.participantId ||
          pairing.additionalStudentIds.contains(participant.participantId)) {
        if (pairing.mentorId != null && pairing.mentorId!.id == hostUserId) {
          hostAccessCount++;
        } else if (pairing.menteeId != null &&
            pairing.menteeId!.id == hostUserId) {
          hostAccessCount++;
        } else if (pairing.additionalStudentIds.isNotEmpty &&
            pairing.additionalStudentIds.any(
              (docRef) => docRef.id == hostUserId,
            )) {
          hostAccessCount++;
        }
      }
    }

    // Consider the participants in the current pairing.
    if (pairingUnit != null) {
      if (pairingUnit.mentor.user.id == hostUserId) {
        hostAccessCount++;
      } else if (pairingUnit.learners.any(
        (participant) => participant.isHost,
      )) {
        hostAccessCount++;
      }
    }

    return hostAccessCount.toDouble();
  }

  double _computeTeachingDeficitScore(PairingUnit? pairingUnit) {
    if (pairingUnit == null) {
      return teachingDeficit;
    } else if (pairingUnit.mentor == this) {
      return teachingDeficit + 1;
    } else {
      return teachingDeficit - (1 / pairingUnit.learners.length);
    }
  }

  double _computeEqualizeParticipation(PairingUnit? pairingUnit) =>
      learnCount + teachCount + (pairingUnit != null ? 1 : 0);

  double _computeMinimizePracticing(PairingUnit? pairingUnit) {
    if (isHost) {
      // The host doesn't count.
      return 0;
    } else if (pairingUnit?.mentor == this) {
      // Teaching isn't practicing.
      return 0;
    } else if (!graduatedLessons.contains(pairingUnit?.lesson)) {
      // The participant is learning something new.
      return 0;
    } else {
      return 1;
    }
  }
}
