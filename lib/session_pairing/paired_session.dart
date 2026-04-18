import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/session_participant.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/session_pairing/learner_pair.dart';
import 'package:social_learning/state/organizer_session_state.dart';
import 'package:social_learning/util/print_util.dart';

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

  debugPrint() {
    dprint('PairedSession');
    for (LearnerPair pair in pairs) {
      dprint('  ${pair.teachingParticipant.id} -> ${pair.learningParticipant.id}: Lesson: ${pair.lesson?.title}');
    }
    dprint('Unpaired participants');
    for (SessionParticipant participant in unpairedParticipants) {
      dprint('  ${participant.id}');
    }
  }
}
