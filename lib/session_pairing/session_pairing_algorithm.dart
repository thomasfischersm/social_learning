import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/session_participant.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/organizer_session_state.dart';

class SessionPairingAlgorithm {
  generateNextSessionPairing(OrganizerSessionState organizerSessionState) {
    // TODO: Determine the possible pairings.
    // TODO: Pick the best pairing.
  }

  List<PairedSession> _generatePossiblePairings(
      OrganizerSessionState organizerSessionState) {
    List<SessionParticipant> allParticipants =
        List.from(organizerSessionState.sessionParticipants);

    return _generatePairings(allParticipants, List.empty(), organizerSessionState);
  }

  _generatePairings(
      List<SessionParticipant> remainingParticipants,
      List<LearnerPair> currentPairs,
      OrganizerSessionState organizerSessionState) {
    if (remainingParticipants.length < 2) {
      return List.from([PairedSession(currentPairs, remainingParticipants)]);
    }

    List<PairedSession> pairings = List.empty();

    for (int i = 1; i < remainingParticipants.length; i++) {
      List<SessionParticipant> thisParticipants =
          List.from(remainingParticipants);
      SessionParticipant participantA = thisParticipants.removeAt(0);
      SessionParticipant participantB = thisParticipants.removeAt(i);

      // One way pair
      Lesson? lesson =
          _pickBestLesson(participantA, participantB, organizerSessionState);

      LearnerPair pair = LearnerPair(
          participantA,
          organizerSessionState.getParticipantUser(participantA)!,
          participantB,
          organizerSessionState.getParticipantUser(participantB)!,
          lesson);

      pairings.addAll(_generatePairings(List.from(thisParticipants),
          List.from(currentPairs)..add(pair), organizerSessionState));

      // TODO: Skip the reverse case when a user is an instructor.

      // Reverse pair
      Lesson? reverseLesson =
          _pickBestLesson(participantA, participantB, organizerSessionState);
      LearnerPair reversePair = pair.reverse(lesson);
      pairings.addAll(_generatePairings(List.from(thisParticipants),
          List.from(currentPairs)..add(reversePair), organizerSessionState));
    }

    return pairings;
  }

  Lesson? _pickBestLesson(
      SessionParticipant participantA,
      SessionParticipant participantB,
      OrganizerSessionState organizerSessionState) {
    User userA = organizerSessionState.getUser(participantA);
    List<Lesson> teachableLessons =
        organizerSessionState.getGraduatedLessons(participantA);

    User userB = organizerSessionState.getUser(participantB);
    List<Lesson> alreadyLearnedLessons =
        organizerSessionState.getGraduatedLessons(participantB);

    // TODO: Handle the case where the user is an instructor.

    // Find relevant lessons.
    Set<Lesson> possibleLessons =
        teachableLessons.toSet().difference(alreadyLearnedLessons.toSet());

    // Find the lesson with the highest sort order.
    if (possibleLessons.isEmpty) {
      return null;
    } else {
      return possibleLessons.reduce((lessonA, lessonB) =>
      (lessonA.sortOrder > lessonB.sortOrder) ? lessonA : lessonB);
    }
  }
}

class LearnerPair {
  SessionParticipant teachingParticipant;
  User teachingUser;
  SessionParticipant learningParticipant;
  User learningUser;
  Lesson? lesson;

  LearnerPair(this.teachingParticipant, this.teachingUser,
      this.learningParticipant, this.learningUser, this.lesson);

  LearnerPair reverse(Lesson? reverseLesson) {
    return LearnerPair(learningParticipant, learningUser, teachingParticipant,
        teachingUser, reverseLesson);
  }
}

class PairedSession {
  List<LearnerPair> pairs;
  List<SessionParticipant> unpairedParticipants;

  PairedSession(this.pairs, this.unpairedParticipants);

  // TODO: Remove pairings that don't have a lesson to teach.
}
