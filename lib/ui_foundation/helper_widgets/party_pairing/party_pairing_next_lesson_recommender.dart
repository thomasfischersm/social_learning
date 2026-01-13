import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/session_participant.dart';
import 'package:social_learning/state/graduation_status.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/organizer_session_state.dart';

class PartyPairingNextLessonRecommender {
  static Lesson? recommendNextLesson(
    OrganizerSessionState organizerSessionState,
    LibraryState libraryState,
    SessionParticipant participant,
  ) {
    List<Lesson> lessons = libraryState.lessons ?? [];
    if (lessons.isEmpty) {
      return null;
    }

    for (Lesson lesson in lessons) {
      GraduationStatus status = organizerSessionState.getGraduationStatus(
        participant,
        lesson,
      );
      if (_shouldSkipLesson(status)) {
        continue;
      }
      return lesson;
    }

    return null;
  }

  static bool _shouldSkipLesson(GraduationStatus status) {
    return status == GraduationStatus.graduated ||
        status == GraduationStatus.practicedThisSession;
  }
}
