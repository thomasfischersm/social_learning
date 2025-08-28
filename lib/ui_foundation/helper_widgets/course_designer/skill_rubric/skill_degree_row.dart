import 'package:flutter/material.dart';
import 'package:social_learning/data/skill_rubric.dart';
import 'package:social_learning/state/course_designer_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/decomposed_course_designer_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/dialog_utils.dart';
import 'package:social_learning/ui_foundation/helper_widgets/value_input_dialog.dart';

class SkillDegreeRow extends StatelessWidget {
  final SkillDimension dimension;
  final SkillDegree degree;
  final CourseDesignerState state;

  const SkillDegreeRow({
    super.key,
    required this.dimension,
    required this.degree,
    required this.state,
  });

  Future<void> _edit(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => ValueInputDialog(
        'Edit degree',
        degree.name,
        'Name',
        'Save',
        (value) =>
            (value == null || value.trim().isEmpty) ? 'Name cannot be empty' : null,
        (newName) => state.updateSkillDegree(
          dimensionId: dimension.id,
          degreeId: degree.id,
          name: newName.trim(),
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(
          children: [
            InkWell(
              onTap: () => _edit(context),
              child: Text('${degree.degree}. ${degree.name}'),
            ),
            const SizedBox(width: 8),
            InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () => _edit(context),
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
          ],
        ),
      ),
    );
  }
}
