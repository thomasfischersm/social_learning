enum SessionPlanActivityType {
  lesson,
  spacedPractice,
  circleTime,
  lectureDemo,
  exercise,
  breakTime,
  groupDiscussion,
}

extension SessionPlanActivityTypeX on SessionPlanActivityType {
  int get value {
    switch (this) {
      case SessionPlanActivityType.lesson:
        return 0;
      case SessionPlanActivityType.spacedPractice:
        return 1;
      case SessionPlanActivityType.circleTime:
        return 2;
      case SessionPlanActivityType.lectureDemo:
        return 3;
      case SessionPlanActivityType.exercise:
        return 4;
      case SessionPlanActivityType.breakTime:
        return 5;
      case SessionPlanActivityType.groupDiscussion:
        return 6;
    }
  }

  static SessionPlanActivityType fromValue(int value) {
    switch (value) {
      case 0:
        return SessionPlanActivityType.lesson;
      case 1:
        return SessionPlanActivityType.spacedPractice;
      case 2:
        return SessionPlanActivityType.circleTime;
      case 3:
        return SessionPlanActivityType.lectureDemo;
      case 4:
        return SessionPlanActivityType.exercise;
      case 5:
        return SessionPlanActivityType.breakTime;
      case 6:
        return SessionPlanActivityType.groupDiscussion;
      default:
        throw ArgumentError('Invalid SessionPlanActivityType value: $value');
    }
  }
}
