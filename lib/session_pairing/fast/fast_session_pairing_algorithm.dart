import 'package:googleapis/dataproc/v1.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/session_participant.dart';
import 'package:social_learning/session_pairing/fast/fast_pairing_context.dart';
import 'package:social_learning/session_pairing/learner_pair.dart';
import 'package:social_learning/session_pairing/paired_session.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/organizer_session_state.dart';

class FastSessionPairingAlgorithm {
  static PairedSession generateNextSessionPairing(
      OrganizerSessionState organizerSessionState, LibraryState libraryState) {
    // TODO: Split into methods.

    // #1 Initialize context.
    FastPairingContext context =
        FastPairingContext(organizerSessionState, libraryState);
    context.debugPrintAll('# 1 Initialize context');

    // #2 Split into initial teaching and learning groups.
    _splitIntoTeachingAndLearningGroups(context);
    context.debugPrintAll('# 2 Split into teaching and learning groups');

    // #3 Attempt to pair the initial groups.
    _attemptIdealPairing(context);
    context.debugPrintAll('# 3 Attempt ideal pairing');

    // #4 Try to pair the leftover group.
    _pairLeftoverGroup(context);
    context.debugPrintAll('# 4 Pair leftover group');

    // #5 Attempt to split pairs to accommodate remaining leftovers.
    _splitPairsToPairLeftOverGroup(context);
    context.debugPrintAll('# 5 Split pairs to pair leftover group');

    return context.getPairedSession();
  }

  static void _splitPairsToPairLeftOverGroup(FastPairingContext context) {
    outer:
    for (int i = 0; i < context.leftoverGroup.length - 1; i++) {
      SessionParticipant leftoverA = context.leftoverGroup[i];

      for (int j = i + 1; j < context.leftoverGroup.length; j++) {
        SessionParticipant leftoverB = context.leftoverGroup[j];

        for (LearnerPair pair in context.pairs) {
          SessionParticipant mentor = pair.teachingParticipant;
          SessionParticipant mentee = pair.learningParticipant;

          // The four possible teach -> learn combinations:
          final combos = <(
            (SessionParticipant, SessionParticipant),
            (SessionParticipant, SessionParticipant)
          )>[
            ((mentor, leftoverA), (mentee, leftoverB)),
            ((mentor, leftoverB), (mentee, leftoverA)),
            ((leftoverA, mentor), (leftoverB, mentee)),
            ((leftoverA, mentee), (leftoverB, mentor)),
          ];

          for (final combo in combos) {
            final (teach1, learn1) = combo.$1;
            final (teach2, learn2) = combo.$2;

            Lesson? lesson1 = context.findBestLessonToTeach(teach1, learn1);
            Lesson? lesson2 = context.findBestLessonToTeach(teach2, learn2);

            if (lesson1 != null && lesson2 != null) {
              // Split the pair.
              context.pairs.remove(pair);
              context.pairs.add(LearnerPair(
                  teach1,
                  context.userByParticipant[teach1]!,
                  learn1,
                  context.userByParticipant[learn1]!,
                  lesson1));
              context.pairs.add(LearnerPair(
                  teach2,
                  context.userByParticipant[teach2]!,
                  learn2,
                  context.userByParticipant[learn2]!,
                  lesson2));
              context.leftoverGroup.remove(leftoverA);
              context.leftoverGroup.remove(leftoverB);
              continue outer;
            }
          }
        }
      }
    }
  }

  static void _pairLeftoverGroup(FastPairingContext context) {
    context.leftoverGroup = [
      ...context.teachingGroup,
      ...context.learningGroup
    ];
    context.sortByGraduateCount(context.leftoverGroup);

    for (int i = 0; i < context.leftoverGroup.length - 1; i++) {
      SessionParticipant mentor = context.leftoverGroup[i];

      for (int j = i + 1; j < context.leftoverGroup.length; j++) {
        SessionParticipant mentee = context.leftoverGroup[j];
        Lesson? bestLesson = context.findBestLessonToTeach(mentor, mentee);

        if (bestLesson == null) {
          // Try the reverse direction.
          bestLesson = context.findBestLessonToTeach(mentee, mentor);
          if (bestLesson != null) {
            // Swap mentor and mentee.
            SessionParticipant temp = mentor;
            mentor = mentee;
            mentee = temp;
          }
        }

        if (bestLesson != null) {
          context.pairs.add(LearnerPair(
              mentor,
              context.userByParticipant[mentor]!,
              mentee,
              context.userByParticipant[mentee]!,
              bestLesson));
          context.leftoverGroup.remove(mentor);
          context.leftoverGroup.remove(mentee);
          break;
        }
      }
    }
  }

  static void _attemptIdealPairing(FastPairingContext context) {
    context.sortByGraduateCount(context.teachingGroup);
    context.sortByGraduateCount(context.learningGroup);

    for (SessionParticipant mentor in List.of(context.teachingGroup)) {
      for (SessionParticipant mentee in context.learningGroup) {
        Lesson? bestLesson = context.findBestLessonToTeach(mentor, mentee);

        if (bestLesson != null) {
          context.pairs.add(LearnerPair(
              mentor,
              context.userByParticipant[mentor]!,
              mentee,
              context.userByParticipant[mentee]!,
              bestLesson));
          context.teachingGroup.remove(mentor);
          context.learningGroup.remove(mentee);
          break;
        }
      }
    }
  }

  static void _splitIntoTeachingAndLearningGroups(FastPairingContext context) {
    List<SessionParticipant> participants = List.from(context.allActiveParticipants);
    context.sortByTeachDeficitAndGraduateCount(participants);
    context.teachingGroup = participants.sublist(0, participants.length ~/ 2);
    context.learningGroup = participants.sublist(participants.length ~/ 2);
  }
}

/*
1. Sort by teachDeficit, graduateCount. (Creator always first)
2. Split into teaching and learning group.
3. Sort both groups by graduateCount.
4. Iterate
4a. Pick the first learner.
4b. Pick the first mentor who can teach something.
4c. Repeat.

5. Create leftover group.
6. Sort leftover group by graduateCount.
7. Iterate
7a. Pick the first leftover person.
7b. See if anyone can teach that person something starting from the end of the leftover group.

8. Iterate the leftover group
8a. Starting with the last two, iterate over the pairings to see if a pairing can teach both leftovers.
8b. If so, split the pairing.

 */
