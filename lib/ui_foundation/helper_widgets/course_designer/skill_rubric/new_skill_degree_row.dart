import 'package:flutter/material.dart';
import 'package:social_learning/data/skill_rubric.dart';
import 'package:social_learning/state/course_designer_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/decomposed_course_designer_card.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'skill_rubric_row.dart';

class NewSkillDegreeRow extends StatefulWidget implements SkillRubricRow {
  final SkillDimension dimension;
  final CourseDesignerState state;

  const NewSkillDegreeRow({
    super.key,
    required this.dimension,
    required this.state,
  });

  @override
  String get pageKey => 'new-degree-${dimension.id}';

  @override
  State<NewSkillDegreeRow> createState() => _NewSkillDegreeRowState();
}

class _NewSkillDegreeRowState extends State<NewSkillDegreeRow> {
  final TextEditingController _controller = TextEditingController();

  Future<void> _add() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await widget.state.addSkillDegree(widget.dimension.id, text);
    _controller.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DecomposedCourseDesignerCard.buildBody(
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: CustomUiConstants.getFilledInputDecoration(
                  context,
                  labelText: 'Add new degree...',
                  enabledColor: Colors.grey.shade400,
                ),
                onSubmitted: (_) => _add(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 20),
              onPressed: _add,
            ),
          ],
        ),
      ),
    );
  }
}
