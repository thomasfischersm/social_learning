import 'package:flutter/material.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/skill_rubric.dart';
import 'package:social_learning/state/course_designer_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/decomposed_course_designer_card.dart';
import 'new_skill_dimension_row.dart';
import 'new_skill_degree_row.dart';
import 'new_skill_lesson_row.dart';
import 'skill_dimension_row.dart';
import 'skill_degree_row.dart';
import 'skill_lesson_row.dart';

/// Base entry used to build the rubric list view and support drag-and-drop.
abstract class SkillRubricEntry {
  /// Unique identifier used as a [PageStorageKey].
  String get pageKey;

  Widget buildWidget(
    BuildContext context,
    CourseDesignerState state,
    LibraryState library,
    int index,
  );
}

class SkillDimensionEntry extends SkillRubricEntry {
  final SkillDimension dimension;
  SkillDimensionEntry(this.dimension);

  @override
  String get pageKey => 'dimension-${dimension.id}';

  @override
  Widget buildWidget(BuildContext context, CourseDesignerState state,
      LibraryState library, int index) {
    return SkillDimensionRow(
      dimension: dimension,
      state: state,
      dragHandleIndex: index,
    );
  }
}

class SkillDegreeEntry extends SkillRubricEntry {
  final SkillDimension dimension;
  final SkillDegree degree;
  SkillDegreeEntry(this.dimension, this.degree);

  @override
  String get pageKey => 'degree-${degree.id}';

  @override
  Widget buildWidget(BuildContext context, CourseDesignerState state,
      LibraryState library, int index) {
    return SkillDegreeRow(
      dimension: dimension,
      degree: degree,
      state: state,
      dragHandleIndex: index,
    );
  }
}

class SkillLessonEntry extends SkillRubricEntry {
  final SkillDimension dimension;
  final SkillDegree degree;
  final Lesson lesson;
  SkillLessonEntry(this.dimension, this.degree, this.lesson);

  @override
  String get pageKey => 'lesson-${lesson.id}';

  @override
  Widget buildWidget(BuildContext context, CourseDesignerState state,
      LibraryState library, int index) {
    return SkillLessonRow(
      dimension: dimension,
      degree: degree,
      lesson: lesson,
      state: state,
      library: library,
      dragHandleIndex: index,
    );
  }
}

class NewSkillLessonEntry extends SkillRubricEntry {
  final SkillDimension dimension;
  final SkillDegree degree;
  NewSkillLessonEntry(this.dimension, this.degree);

  @override
  String get pageKey => 'new-lesson-${degree.id}';

  @override
  Widget buildWidget(BuildContext context, CourseDesignerState state,
      LibraryState library, int index) {
    return NewSkillLessonRow(
      dimension: dimension,
      degree: degree,
      state: state,
      library: library,
    );
  }
}

class NewSkillDegreeEntry extends SkillRubricEntry {
  final SkillDimension dimension;
  NewSkillDegreeEntry(this.dimension);

  @override
  String get pageKey => 'new-degree-${dimension.id}';

  @override
  Widget buildWidget(BuildContext context, CourseDesignerState state,
      LibraryState library, int index) {
    return NewSkillDegreeRow(
      dimension: dimension,
      state: state,
    );
  }
}

class NewSkillDimensionEntry extends SkillRubricEntry {
  NewSkillDimensionEntry();

  @override
  String get pageKey => 'new-dimension';

  @override
  Widget buildWidget(BuildContext context, CourseDesignerState state,
      LibraryState library, int index) {
    return NewSkillDimensionRow(state: state);
  }
}

class DimensionFooterEntry extends SkillRubricEntry {
  final String dimensionId;
  DimensionFooterEntry(this.dimensionId);

  @override
  String get pageKey => 'footer-$dimensionId';

  @override
  Widget buildWidget(BuildContext context, CourseDesignerState state,
      LibraryState library, int index) {
    return DecomposedCourseDesignerCard.buildFooter(bottomMargin: 16);
  }
}
