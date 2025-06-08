import 'package:flutter/material.dart';
import 'package:social_learning/data/learning_objective.dart';
import 'package:social_learning/data/data_helpers/learning_objective_functions.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_learning_objectives/Learning_objectives_context.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_learning_objectives/edit_learning_objective_dialog.dart';
import 'package:social_learning/ui_foundation/helper_widgets/dialog_utils.dart';
import 'package:social_learning/ui_foundation/helper_widgets/value_input_dialog.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/decomposed_course_designer_card.dart';

class LearningObjectiveEntry extends StatelessWidget {
  final LearningObjective objective;
  final LearningObjectivesContext objectiveContext;

  const LearningObjectiveEntry({
    super.key,
    required this.objective,
    required this.objectiveContext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTitleRow(context),
        if (objective.description != null &&
            objective.description!.trim().isNotEmpty)
          DecomposedCourseDesignerCard.buildBody(_buildDescription(context)),
      ],
    );
  }

  Widget _buildTitleRow(BuildContext context) {
    return DecomposedCourseDesignerCard.buildHeaderWithIcons(objective.name, [InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () => _onEditTapped(context),
      child: const Padding(
        padding: EdgeInsets.all(4.0),
        child: Icon(Icons.edit, size: 16, color: Colors.grey),
      ),
    ),
      const SizedBox(width: 6),
      InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () => _onDeleteTapped(context),
        child: const Padding(
          padding: EdgeInsets.all(4.0),
          child: Icon(Icons.delete, size: 16, color: Colors.grey),
        ),
      ),]);
  }

  Widget _buildDescription(BuildContext context) {
    final desc = objective.description?.trim() ?? '';
    if (desc.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
      child: Text(
        desc,
        style: CustomTextStyles.getBody(context),
      ),
    );
  }

  void _onEditTapped(BuildContext context) {
    _editObjective(context);
  }

  void _onDeleteTapped(BuildContext context) {
    DialogUtils.showConfirmationDialog(
      context,
      'Delete learning objective?',
      'Are you sure you want to delete "${objective.name}"?',
      () async {
        await objectiveContext.deleteObjective(objective);
      },
    );
  }

  void _editObjective(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => EditLearningObjectiveDialog(
        objective: objective,
        objectivesContext: objectiveContext,
      ),
    );
  }

}
