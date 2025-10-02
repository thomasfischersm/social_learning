import 'package:collection/collection.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/practice_record.dart';
import 'package:social_learning/data/session_participant.dart';
import 'package:social_learning/session_pairing/learner_pair.dart';
import 'package:social_learning/session_pairing/paired_session.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/organizer_session_state.dart';
import 'package:social_learning/data/user.dart';

class FastPairingContext {
  final OrganizerSessionState organizerSessionState;
  final LibraryState libraryState;

  final graduateCountByParticipant = <SessionParticipant, int>{};
  final teachCountByParticipant = <SessionParticipant, int>{};
  final graduatedLessonIdsByParticipant = <SessionParticipant, Set<String>>{};
  final userByParticipant = <SessionParticipant, User>{};

  List<User> get allUsers => organizerSessionState.participantUsers;

  List<SessionParticipant> get allParticipants =>
      organizerSessionState.sessionParticipants;

  List<SessionParticipant> learningGroup = [];
  List<SessionParticipant> teachingGroup = [];
  List<SessionParticipant> leftoverGroup = [];

  List<LearnerPair> pairs = [];

  FastPairingContext(this.organizerSessionState, this.libraryState) {
    for (SessionParticipant participant in allParticipants) {
      // Init graduate counts.
      List<Lesson> graduatedLessons =
          organizerSessionState.getGraduatedLessons(participant);
      Set<String> graduatedLessonIds =
          Set.from(graduatedLessons.map((lesson) => lesson.id));
      int graduateCount = graduatedLessonIds.length;

      graduatedLessonIdsByParticipant[participant] = graduatedLessonIds;
      graduateCountByParticipant[participant] = graduateCount;

      // Init teach counts.
      int teachCount = organizerSessionState
          .getTeachCountForUser(participant.participantId.id);
      int learnCount = organizerSessionState
          .getLearnCountForUser(participant.participantId.id);
      int teachDeficit = learnCount - teachCount;
      teachCountByParticipant[participant] = teachDeficit;

      // Init user lookup.
      User? user = organizerSessionState.getUser(participant);
      if (user != null) {
        userByParticipant[participant] = user;
      }
    }
  }

  void sortByTeachDeficitAndGraduateCount(
      List<SessionParticipant> participants) {
    participants.sort((a, b) {
      if (a.isInstructor && !b.isInstructor) {
        return -1; // a comes before b
      } else if (!a.isInstructor && b.isInstructor) {
        return 1; // b comes before a
      }

      int teachDeficitA = teachCountByParticipant[a] ?? 0;
      int teachDeficitB = teachCountByParticipant[b] ?? 0;
      if (teachDeficitA != teachDeficitB) {
        return teachDeficitB.compareTo(teachDeficitA); // Descending
      }
      int graduateCountA = graduateCountByParticipant[a] ?? 0;
      int graduateCountB = graduateCountByParticipant[b] ?? 0;
      return graduateCountB.compareTo(graduateCountA); // Descending
    });
  }

  void sortByGraduateCount(List<SessionParticipant> participants) {
    participants.sort((a, b) {
      if (a.isInstructor && !b.isInstructor) {
        return -1; // a comes before b
      } else if (!a.isInstructor && b.isInstructor) {
        return 1; // b comes before a
      }

      int graduateCountA = graduateCountByParticipant[a] ?? 0;
      int graduateCountB = graduateCountByParticipant[b] ?? 0;
      return graduateCountB.compareTo(graduateCountA); // Descending
    });
  }

  Lesson? findBestLessonToTeach(
      SessionParticipant mentor, SessionParticipant mentee) {
    // TODO: Admin and creator can always teach

    Set<String> mentorLessonIds = graduatedLessonIdsByParticipant[mentor] ?? {};
    Set<String> menteeLessonIds = graduatedLessonIdsByParticipant[mentee] ?? {};

    Set<String> teachableLessonIds =
        mentorLessonIds.difference(menteeLessonIds);
    Set<Lesson> teachableLessons =
        teachableLessonIds.map((id) => libraryState.findLesson(id)!).toSet();
    Lesson? bestLesson = teachableLessons.isEmpty
        ? null
        : teachableLessons.reduce((lessonA, lessonB) {
            return (lessonA.sortOrder < lessonB.sortOrder) ? lessonA : lessonB;
          });
    return bestLesson;
  }

  PairedSession getPairedSession() {
    return PairedSession(pairs, leftoverGroup);
  }

  void debugPrintAll(String label) {
    print('-------------------------------');
    print('FastPairingContext dump: $label');

    _debugPrintUsers('All participants', allParticipants);
    _debugPrintUsers('Teaching group', teachingGroup);
    _debugPrintUsers('Learning group', learningGroup);
    _debugPrintUsers('Leftover group', leftoverGroup);
    _debugPrintPairs();
  }

  void _debugPrintUsers(String label, List<SessionParticipant> participants) {
    print('\n$label:');
    for (var participant in participants) {
      var user = userByParticipant[participant];
      print('  Participant ID: ${participant.id}, User: ${user?.displayName}');
    }
  }

  void _debugPrintPairs() {
    print('\nLearner Pairs:');
    for (var pair in pairs) {
      print(
          '  Mentor: ${pair.teachingParticipant.id} (${pair.teachingUser.displayName}) -> Mentee: ${pair.learningParticipant.id} (${pair.learningUser.displayName}), Lesson: ${pair.lesson?.title}');
    }
  }
}
