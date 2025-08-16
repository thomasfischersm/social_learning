import 'package:flutter/material.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_session_plan/session_plan_context.dart';
import '../../../data/session_plan_block.dart';
import '../course_designer/decomposed_course_designer_card.dart';
import '../dialog_utils.dart';
import '../value_input_dialog.dart';

class SessionBlockHeaderRow extends StatelessWidget {
  final SessionPlanBlock block;
  final SessionPlanContext contextData;
  final int reorderIndex;

  const SessionBlockHeaderRow({
    super.key,
    required this.block,
    required this.contextData,
    required this.reorderIndex,
  });

  void _editBlockName(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => ValueInputDialog(
        'Edit Block Name',
        block.name ?? '(Untitled)',
        'Block name',
        'Save',
            (value) => (value == null || value.trim().isEmpty)
            ? 'Name cannot be empty'
            : null,
            (newName) =>
            contextData.updateBlockName(blockId: block.id!, newName: newName.trim()),
      ),
    );
  }

  void _confirmDeleteBlock(BuildContext context) {
    DialogUtils.showConfirmationDialog(
      context,
      'Delete Block?',
      'Are you sure you want to delete this session block and all its activities?',
          () => contextData.deleteBlock(block.id!),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- duration ----------
    final totalMinutes = contextData.getTotalDurationMinutesForBlock(block.id!);
    final String? durationStr =
    totalMinutes == 0 ? null : contextData.getDurationStringForBlock(block.id!);

    // --- actions / icons ----
    final List<Widget> actions = [
      if (durationStr != null)
        Padding(
          padding: const EdgeInsets.only(right: 8.0), // space before real icons
          child: Text(
            durationStr,
            style: const TextStyle(
              fontWeight: FontWeight.normal,
              color: Colors.grey,
            ),
          ),
        ),
      IconButton(
        icon: const Icon(Icons.edit, size: 20),
        tooltip: 'Edit block name',
        onPressed: () => _editBlockName(context),
      ),
      IconButton(
        icon: const Icon(Icons.delete_outline, size: 20),
        tooltip: 'Delete block',
        onPressed: () => _confirmDeleteBlock(context),
      ),
    ];

    final header = DecomposedCourseDesignerCard.buildHeaderWithIcons(
      block.name ?? '(Untitled)',
      actions,
    );

    return ReorderableDragStartListener(
      index: reorderIndex,
      child: header,
    );
  }
}
