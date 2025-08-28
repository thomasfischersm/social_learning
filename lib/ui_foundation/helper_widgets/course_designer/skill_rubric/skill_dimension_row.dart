import 'package:flutter/material.dart';
import 'package:social_learning/data/skill_rubric.dart';
import 'package:social_learning/state/course_designer_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/decomposed_course_designer_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/dialog_utils.dart';
import 'package:social_learning/ui_foundation/helper_widgets/value_input_dialog.dart';

class SkillDimensionRow extends StatelessWidget {
  final SkillDimension dimension;
  final CourseDesignerState state;

  const SkillDimensionRow({
    super.key,
    required this.dimension,
    required this.state,
  });

  Future<void> _edit(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => ValueInputDialog(
        'Edit dimension',
        dimension.name,
        'Name',
        'Save',
        (value) =>
            (value == null || value.trim().isEmpty) ? 'Name cannot be empty' : null,
        (newName) => state.updateSkillDimension(
          dimensionId: dimension.id,
          name: newName.trim(),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    DialogUtils.showConfirmationDialog(
      context,
      'Delete dimension?',
      'This will remove the dimension and all its degrees.',
      () => state.deleteSkillDimension(dimension.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final header = DecomposedCourseDesignerCard.buildHeaderWithIcons(
      dimension.name,
      [
        InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () => _edit(context),
          child: const Padding(
            padding: EdgeInsets.all(4.0),
            child: Icon(Icons.edit, size: 20, color: Colors.grey),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () => _confirmDelete(context),
          child: const Padding(
            padding: EdgeInsets.all(4.0),
            child: Icon(Icons.delete_outline, size: 20, color: Colors.grey),
          ),
        ),
      ],
    );

    return InkWell(onTap: () => _edit(context), child: header);
  }
}
