import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/learning_strategy_enum.dart';

class SessionParticipant {
  String? id;
  DocumentReference sessionId;
  DocumentReference participantId;
  String participantUid;
  bool isInstructor;
  bool isActive;
  int teachCount;
  int learnCount;
  LearningStrategyEnum learningStrategy;

  SessionParticipant(
      this.id,
      this.sessionId,
      this.participantId,
      this.participantUid,
      this.isInstructor,
      this.isActive,
      this.teachCount,
      this.learnCount,
      this.learningStrategy);

  SessionParticipant.fromSnapshot(QueryDocumentSnapshot<Map<String, dynamic>> e)
      : id = e.id,
        sessionId = e.data()['sessionId'] as DocumentReference,
        participantId = e.data()['participantId'] as DocumentReference,
        participantUid = e.data()['participantUid'] as String,
        isInstructor = e.data()['isInstructor'] as bool,
        isActive = e.data()['isActive'] as bool,
        teachCount = e.data()['teachCount'] as int? ?? 0,
        learnCount = e.data()['learnCount'] as int? ?? 0,
        learningStrategy = LearningStrategyEnum.values[
            e.data()['learningStrategy'] as int? ??
                LearningStrategyEnum.preferred.index];
}
