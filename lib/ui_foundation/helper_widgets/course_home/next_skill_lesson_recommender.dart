import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/skill_assessment.dart';
import 'package:social_learning/data/skill_rubric.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/student_state.dart';

import '../../../data/user.dart';

class NextSkillLessonRecommender {
  static Lesson? recommendNextLesson(
      LibraryState libraryState,
      ApplicationState applicationState,
      StudentState studentState,
      SkillRubric skillRubric) {
    // Collect context.
    var context = _NextSkillLessonRecommenderContext(
        libraryState, applicationState, studentState, skillRubric);

    // Create lesson list.
    List<_LessonMetaInfo> lessonMetaInfos = [];
    for (SkillDimension dimension in skillRubric.dimensions) {
      SkillAssessmentDimension? assessmentDimension = context
          .skillAssessment?.dimensions
          .firstWhereOrNull((d) => d.id == dimension.id);
      if (assessmentDimension == null) {
        continue;
      }

      for (SkillDegree degree in dimension.degrees) {
        if (degree.degree != assessmentDimension.degree) {
          continue;
        }

        for (DocumentReference lessonRef in degree.lessonRefs) {
          Lesson? lesson = context.lessonsById[lessonRef.id];
          if (lesson == null) {
            continue;
          }

          try {
            lessonMetaInfos.add(_LessonMetaInfo.create(context, lessonRef,
                dimension, degree, context.skillAssessment));
          } on _NoSuchLessonException {
            // Skip this lesson.
          }
        }
      }
    }

    // Sort lessons.
    lessonMetaInfos.sort((lessonInfoA, lessonInfoB) {
      if (lessonInfoA.skillDimension == lessonInfoB.skillDimension) {
        // Handle the case of the same dimension.

        // If one hasn't graduated, return that.
        if (lessonInfoA.lessonCount.isGraduated !=
            lessonInfoB.lessonCount.isGraduated) {
          return lessonInfoA.lessonCount.isGraduated ? 1 : -1;
        }

        // Return the one with less practice count.
        if (lessonInfoA.lessonCount.practiceCount !=
            lessonInfoB.lessonCount.practiceCount) {
          return lessonInfoA.lessonCount.practiceCount
              .compareTo(lessonInfoB.lessonCount.practiceCount);
        }

        // Return by lesson sort order.
        return lessonInfoA.lesson.sortOrder
            .compareTo(lessonInfoB.lesson.sortOrder);
      } else {
        // Handle the case of different dimensions.
        double deltaPercent =
            lessonInfoA.dimensionPercent - lessonInfoB.dimensionPercent;

        double factor = deltaPercent /
            ((lessonInfoA.degreeStep + lessonInfoB.degreeStep) / 2);

        _LessonMetaInfo earlier =
            lessonInfoA.dimensionPercent < lessonInfoB.dimensionPercent
                ? lessonInfoA
                : lessonInfoB;
        _LessonMetaInfo later =
            earlier == lessonInfoA ? lessonInfoB : lessonInfoA;

        double earlierScore = earlier.lessonCount.practiceCount.toDouble();
        double laterScore =
            (later.lessonCount.practiceCount.toDouble()) * factor;

        int result = earlierScore.compareTo(laterScore);

        if (result == 0) {
          // If scores are equal, fall back to graduation status.
          if (lessonInfoA.lessonCount.isGraduated !=
              lessonInfoB.lessonCount.isGraduated) {
            return lessonInfoA.lessonCount.isGraduated ? 1 : -1;
          }

          // Fall back to lesson sort order.
          return lessonInfoA.lesson.sortOrder
              .compareTo(lessonInfoB.lesson.sortOrder);
        }

        if (earlier == lessonInfoA) {
          return result;
        } else {
          return -result;
        }
      }
    });

    return lessonMetaInfos.firstOrNull?.lesson;
  }
}

class _LessonMetaInfo {
  Lesson lesson;
  LessonCount lessonCount;
  SkillDimension skillDimension;
  SkillDegree skillDegree;
  double dimensionPercent;
  double degreeStep;

  _LessonMetaInfo(this.lesson, this.lessonCount, this.skillDimension,
      this.skillDegree, this.dimensionPercent, this.degreeStep);

  factory _LessonMetaInfo.create(
      _NextSkillLessonRecommenderContext context,
      DocumentReference lessonRef,
      SkillDimension skillDimension,
      SkillDegree skillDegree,
      CourseSkillAssessment? skillAssessment) {
    String lessonId = lessonRef.id;

    Lesson? lesson = context.lessonsById[lessonId];

    LessonCount? lessonCount = context.lessonCountByLessonId[lessonId];

    double dimensionPercent =
        context.dimensionPercentByDimensionId[skillDimension.id] ?? 0.0;

    double degreeStep = skillDimension.degrees.isNotEmpty
        ? 1.0 / skillDimension.degrees.length
        : 1;

    if (lesson == null || lessonCount == null) {
      throw _NoSuchLessonException();
    } else {
      return _LessonMetaInfo(lesson, lessonCount, skillDimension, skillDegree,
          dimensionPercent, degreeStep);
    }
  }
}

class _NoSuchLessonException {}

class _NextSkillLessonRecommenderContext {
  late Map<String, Lesson> lessonsById;
  late Map<String, LessonCount> lessonCountByLessonId;
  late Map<String, double> dimensionPercentByDimensionId;
  SkillRubric skillRubric;
  CourseSkillAssessment? skillAssessment;

  _NextSkillLessonRecommenderContext(
      LibraryState libraryState,
      ApplicationState applicationState,
      StudentState studentState,
      this.skillRubric) {
    Course course = libraryState.selectedCourse!;
    List<SkillAssessmentDimension> assessmentDimensions = applicationState
            .currentUser
            ?.getCourseSkillAssessment(course)
            ?.dimensions ??
        [];

    lessonsById = {
      for (var lesson in libraryState.lessons ?? []) lesson.id!: lesson
    };
    lessonCountByLessonId = {
      for (Lesson lesson in libraryState.lessons ?? [])
        lesson.id!: studentState.getCountsForLesson(lesson)
    };
    dimensionPercentByDimensionId = {
      for (SkillAssessmentDimension dimension in assessmentDimensions)
        dimension.id: dimension.maxDegrees != 0
            ? dimension.degree / dimension.maxDegrees
            : 0.0
    };
    skillAssessment =
        applicationState.currentUser?.getCourseSkillAssessment(course);
  }
}
