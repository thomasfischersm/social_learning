import 'dart:ui';

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

  Color get color {
    switch (this) {
      case SessionPlanActivityType.lesson:
        return const Color(0xFF81C784); // leafy green
      case SessionPlanActivityType.spacedPractice:
        return const Color(0xFF4DD0E1); // minty teal
      case SessionPlanActivityType.circleTime:
        return const Color(0xFFFFB74D); // apricot
      case SessionPlanActivityType.lectureDemo:
        return const Color(0xFFFFD54F); // golden yellow
      case SessionPlanActivityType.exercise:
        return const Color(0xFFF06292); // coral pink
      case SessionPlanActivityType.breakTime:
        return const Color(0xFFB0BEC5); // lavender gray
      case SessionPlanActivityType.groupDiscussion:
        return const Color(0xFF9575CD); // periwinkle
    }
  }

  String get humanLabel {
    switch (this) {
      case SessionPlanActivityType.lesson:
        return 'Lesson';
      case SessionPlanActivityType.spacedPractice:
        return 'Spaced Practice';
      case SessionPlanActivityType.circleTime:
        return 'Circle Time';
      case SessionPlanActivityType.lectureDemo:
        return 'Lecture/Demo';
      case SessionPlanActivityType.exercise:
        return 'Exercise';
      case SessionPlanActivityType.breakTime:
        return 'Break';
      case SessionPlanActivityType.groupDiscussion:
        return 'Group Discussion';
    }
  }
}
