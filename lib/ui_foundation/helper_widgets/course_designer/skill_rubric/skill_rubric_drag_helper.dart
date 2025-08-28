import 'package:social_learning/state/course_designer_state.dart';
import 'skill_rubric_row.dart';
import 'skill_dimension_row.dart';
import 'skill_degree_row.dart';
import 'skill_lesson_row.dart';
import 'new_skill_dimension_row.dart';
import 'new_skill_degree_row.dart';
import 'new_skill_lesson_row.dart';

class SkillRubricDragHelper {
  static Future<void> handleReorder({
    required CourseDesignerState state,
    required List<SkillRubricRow> rows,
    required int oldIndex,
    required int newIndex,
  }) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final dragged = rows[oldIndex];
    final target = rows[newIndex];

    if (dragged is SkillDimensionRow && target is SkillDimensionRow) {
      await _handleDimensionToDimension(state, dragged, target);
    } else if (dragged is SkillDimensionRow &&
        target is NewSkillDimensionRow) {
      await _handleDimensionToNewDimension(state, dragged);
    } else if (dragged is SkillDegreeRow && target is SkillDegreeRow) {
      await _handleDegreeToDegree(state, dragged, target);
    } else if (dragged is SkillDegreeRow && target is SkillLessonRow) {
      await _handleDegreeToLesson(state, dragged, target);
    } else if (dragged is SkillDegreeRow && target is NewSkillDegreeRow) {
      await _handleDegreeToNewDegree(state, dragged);
    } else if (dragged is SkillLessonRow && target is SkillLessonRow) {
      await _handleLessonToLesson(state, dragged, target);
    } else if (dragged is SkillLessonRow && target is NewSkillLessonRow) {
      await _handleLessonToNewLesson(state, dragged, target);
    } else if (dragged is SkillLessonRow && target is SkillDegreeRow) {
      await _handleLessonToDegree(state, dragged, target);
    }
  }

  static Future<void> _handleDimensionToDimension(
    CourseDesignerState state,
    SkillDimensionRow dragged,
    SkillDimensionRow target,
  ) async {
    final newIndex = state.skillRubric?.dimensions
            .indexWhere((d) => d.id == target.dimension.id) ??
        0;
    await state.moveSkillDimension(
      dimensionId: dragged.dimension.id,
      newIndex: newIndex,
    );
  }

  static Future<void> _handleDimensionToNewDimension(
    CourseDesignerState state,
    SkillDimensionRow dragged,
  ) async {
    final newIndex =
        (state.skillRubric?.dimensions.length ?? 1) - 1;
    await state.moveSkillDimension(
      dimensionId: dragged.dimension.id,
      newIndex: newIndex,
    );
  }

  static Future<void> _handleDegreeToDegree(
    CourseDesignerState state,
    SkillDegreeRow dragged,
    SkillDegreeRow target,
  ) async {
    if (target.dimension.id != dragged.dimension.id) return;
    final dim = state.skillRubric?.dimensions
        .firstWhere((d) => d.id == dragged.dimension.id);
    final newIndex =
        dim?.degrees.indexWhere((d) => d.id == target.degree.id) ?? 0;
    await state.moveSkillDegree(
      dimensionId: dragged.dimension.id,
      degreeId: dragged.degree.id,
      newIndex: newIndex,
    );
  }

  static Future<void> _handleDegreeToLesson(
    CourseDesignerState state,
    SkillDegreeRow dragged,
    SkillLessonRow target,
  ) async {
    if (target.dimension.id != dragged.dimension.id) return;
    final dim = state.skillRubric?.dimensions
        .firstWhere((d) => d.id == dragged.dimension.id);
    final newIndex =
        dim?.degrees.indexWhere((d) => d.id == target.degree.id) ?? 0;
    await state.moveSkillDegree(
      dimensionId: dragged.dimension.id,
      degreeId: dragged.degree.id,
      newIndex: newIndex,
    );
  }

  static Future<void> _handleDegreeToNewDegree(
    CourseDesignerState state,
    SkillDegreeRow dragged,
  ) async {
    final dim = state.skillRubric?.dimensions
        .firstWhere((d) => d.id == dragged.dimension.id);
    final newIndex = (dim?.degrees.length ?? 1) - 1;
    await state.moveSkillDegree(
      dimensionId: dragged.dimension.id,
      degreeId: dragged.degree.id,
      newIndex: newIndex,
    );
  }

  static Future<void> _handleLessonToLesson(
    CourseDesignerState state,
    SkillLessonRow dragged,
    SkillLessonRow target,
  ) async {
    final targetDimId = target.dimension.id;
    final targetDegreeId = target.degree.id;
    final toDeg = state.skillRubric!.dimensions
        .firstWhere((d) => d.id == targetDimId)
        .degrees
        .firstWhere((d) => d.id == targetDegreeId);
    final toIndex =
        toDeg.lessonRefs.indexWhere((r) => r.id == target.lesson.id!);
    final fromDeg = state.skillRubric!.dimensions
        .firstWhere((d) => d.id == dragged.dimension.id)
        .degrees
        .firstWhere((d) => d.id == dragged.degree.id);
    final fromIndex =
        fromDeg.lessonRefs.indexWhere((r) => r.id == dragged.lesson.id!);
    await state.moveSkillLesson(
      fromDegreeId: dragged.degree.id,
      fromLessonIndex: fromIndex,
      toDegreeId: targetDegreeId,
      toLessonIndex: toIndex,
    );
  }

  static Future<void> _handleLessonToNewLesson(
    CourseDesignerState state,
    SkillLessonRow dragged,
    NewSkillLessonRow target,
  ) async {
    final targetDimId = target.dimension.id;
    final targetDegreeId = target.degree.id;
    final toDeg = state.skillRubric!.dimensions
        .firstWhere((d) => d.id == targetDimId)
        .degrees
        .firstWhere((d) => d.id == targetDegreeId);
    final toIndex = toDeg.lessonRefs.length;
    final fromDeg = state.skillRubric!.dimensions
        .firstWhere((d) => d.id == dragged.dimension.id)
        .degrees
        .firstWhere((d) => d.id == dragged.degree.id);
    final fromIndex =
        fromDeg.lessonRefs.indexWhere((r) => r.id == dragged.lesson.id!);
    await state.moveSkillLesson(
      fromDegreeId: dragged.degree.id,
      fromLessonIndex: fromIndex,
      toDegreeId: targetDegreeId,
      toLessonIndex: toIndex,
    );
  }

  static Future<void> _handleLessonToDegree(
    CourseDesignerState state,
    SkillLessonRow dragged,
    SkillDegreeRow target,
  ) async {
    final targetDegreeId = target.degree.id;
    final fromDeg = state.skillRubric!.dimensions
        .firstWhere((d) => d.id == dragged.dimension.id)
        .degrees
        .firstWhere((d) => d.id == dragged.degree.id);
    final fromIndex =
        fromDeg.lessonRefs.indexWhere((r) => r.id == dragged.lesson.id!);
    await state.moveSkillLesson(
      fromDegreeId: dragged.degree.id,
      fromLessonIndex: fromIndex,
      toDegreeId: targetDegreeId,
      toLessonIndex: 0,
    );
  }
}
