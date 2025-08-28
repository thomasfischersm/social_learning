import 'package:social_learning/state/course_designer_state.dart';
import 'skill_rubric_entry.dart';

class SkillRubricDragHelper {
  static Future<void> handleReorder({
    required CourseDesignerState state,
    required List<SkillRubricEntry> entries,
    required int oldIndex,
    required int newIndex,
  }) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final dragged = entries[oldIndex];
    final target = entries[newIndex];

    if (dragged is SkillDimensionEntry && target is SkillDimensionEntry) {
      await _handleDimensionToDimension(state, dragged, target);
    } else if (dragged is SkillDimensionEntry &&
        target is NewSkillDimensionEntry) {
      await _handleDimensionToNewDimension(state, dragged);
    } else if (dragged is SkillDegreeEntry && target is SkillDegreeEntry) {
      await _handleDegreeToDegree(state, dragged, target);
    } else if (dragged is SkillDegreeEntry && target is SkillLessonEntry) {
      await _handleDegreeToLesson(state, dragged, target);
    } else if (dragged is SkillDegreeEntry && target is NewSkillDegreeEntry) {
      await _handleDegreeToNewDegree(state, dragged);
    } else if (dragged is SkillLessonEntry && target is SkillLessonEntry) {
      await _handleLessonToLesson(state, dragged, target);
    } else if (dragged is SkillLessonEntry && target is NewSkillLessonEntry) {
      await _handleLessonToNewLesson(state, dragged, target);
    } else if (dragged is SkillLessonEntry && target is SkillDegreeEntry) {
      await _handleLessonToDegree(state, dragged, target);
    }
  }

  static Future<void> _handleDimensionToDimension(
    CourseDesignerState state,
    SkillDimensionEntry dragged,
    SkillDimensionEntry target,
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
    SkillDimensionEntry dragged,
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
    SkillDegreeEntry dragged,
    SkillDegreeEntry target,
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
    SkillDegreeEntry dragged,
    SkillLessonEntry target,
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
    SkillDegreeEntry dragged,
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
    SkillLessonEntry dragged,
    SkillLessonEntry target,
  ) async {
    final targetDimId = target.dimension.id;
    final targetDegreeId = target.degree.id;
    final toDeg = state.skillRubric?.dimensions
        .firstWhere((d) => d.id == targetDimId)
        .degrees
        .firstWhere((d) => d.id == targetDegreeId);
    final toIndex =
        toDeg.lessonRefs.indexWhere((r) => r.id == target.lesson.id!);
    final fromDeg = state.skillRubric?.dimensions
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
    SkillLessonEntry dragged,
    NewSkillLessonEntry target,
  ) async {
    final targetDimId = target.dimension.id;
    final targetDegreeId = target.degree.id;
    final toDeg = state.skillRubric?.dimensions
        .firstWhere((d) => d.id == targetDimId)
        .degrees
        .firstWhere((d) => d.id == targetDegreeId);
    final toIndex = toDeg.lessonRefs.length;
    final fromDeg = state.skillRubric?.dimensions
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
    SkillLessonEntry dragged,
    SkillDegreeEntry target,
  ) async {
    final targetDegreeId = target.degree.id;
    final fromDeg = state.skillRubric?.dimensions
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
