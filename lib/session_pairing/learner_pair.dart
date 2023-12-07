import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/session_participant.dart';
import 'package:social_learning/data/user.dart';

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