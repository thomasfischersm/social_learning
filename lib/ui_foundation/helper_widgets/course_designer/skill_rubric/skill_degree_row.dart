import 'package:flutter/material.dart';
import 'package:social_learning/data/skill_rubric.dart';
import 'package:social_learning/state/course_designer_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/decomposed_course_designer_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/skill_rubric/skill_description_dialog.dart';
import 'package:social_learning/ui_foundation/helper_widgets/dialog_utils.dart';
import 'skill_rubric_row.dart';

class SkillDegreeRow extends StatelessWidget implements SkillRubricRow {
  final SkillDimension dimension;
  final SkillDegree degree;
  final CourseDesignerState state;
  final int dragHandleIndex;

  const SkillDegreeRow({
    super.key,
    required this.dimension,
    required this.degree,
    required this.state,
    required this.dragHandleIndex,
  });

  Future<void> _openDialog(BuildContext context, bool editMode) async {
    await showDialog(
      context: context,
      builder: (_) => SkillDescriptionDialog(
        itemType: 'Degree',
        initialName: degree.name,
        initialDescription: degree.description,
        startInEditMode: editMode,
        onSave: (name, description) => state.updateSkillDegree(
          dimensionId: dimension.id,
          degreeId: degree.id,
          name: name,
          description: description,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    DialogUtils.showConfirmationDialog(
      context,
      'Delete degree?',
      'Are you sure you want to delete this degree?',
      () => state.deleteSkillDegree(
          dimensionId: dimension.id, degreeId: degree.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecomposedCourseDesignerCard.buildBody(
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
        child: Row(
          children: [
            InkWell(
              onTap: () => _openDialog(context, true),
              child: Text('${degree.degree}. ${degree.name}'),
            ),

            if (degree.description?.trim().isNotEmpty ?? false) ...[
              InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () => _openDialog(context, false),
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(Icons.notes, size: 18, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 6),
            ],
            InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () => _openDialog(context, true),
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(Icons.edit, size: 18, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 6),
            InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () => _confirmDelete(context),
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(Icons.delete_outline, size: 18, color: Colors.grey),
              ),
            ),
            const Spacer(),
            ReorderableDragStartListener(
              index: dragHandleIndex,
              child: const Icon(Icons.drag_handle, color: Colors.grey, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  @override
  String get pageKey => 'degree-${degree.id}';
}
