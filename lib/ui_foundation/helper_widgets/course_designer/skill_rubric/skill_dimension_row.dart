import 'package:flutter/material.dart';
import 'package:social_learning/data/skill_rubric.dart';
import 'package:social_learning/state/course_designer_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/decomposed_course_designer_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/skill_rubric/skill_description_dialog.dart';
import 'package:social_learning/ui_foundation/helper_widgets/dialog_utils.dart';

class SkillDimensionRow extends StatelessWidget {
  final SkillDimension dimension;
  final CourseDesignerState state;

  const SkillDimensionRow({
    super.key,
    required this.dimension,
    required this.state,
  });

  Future<void> _openDialog(BuildContext context, bool editMode) async {
    await showDialog(
      context: context,
      builder: (_) => SkillDescriptionDialog(
        itemType: 'Dimension',
        initialName: dimension.name,
        initialDescription: dimension.description,
        startInEditMode: editMode,
        onSave: (name, description) => state.updateSkillDimension(
          dimensionId: dimension.id,
          name: name,
          description: description,
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
    final icons = <Widget>[];
    if (dimension.description?.trim().isNotEmpty ?? false) {
      icons.add(
        InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () => _openDialog(context, false),
          child: const Padding(
            padding: EdgeInsets.all(4.0),
            child: Icon(Icons.notes, size: 20, color: Colors.grey),
          ),
        ),
      );
    }
    icons.addAll([
      InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () => _openDialog(context, true),
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
    ]);

    final header =
        DecomposedCourseDesignerCard.buildHeaderWithIcons(dimension.name, icons);

    return InkWell(onTap: () => _openDialog(context, true), child: header);
  }
}
