import 'package:flutter/material.dart';
import 'package:social_learning/state/course_designer_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/decomposed_course_designer_card.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'skill_rubric_row.dart';

class NewSkillDimensionRow extends StatefulWidget
    implements SkillRubricRow {
  final CourseDesignerState state;

  const NewSkillDimensionRow({super.key, required this.state});

  @override
  String get pageKey => 'new-dimension';

  @override
  State<NewSkillDimensionRow> createState() => _NewSkillDimensionRowState();
}

class _NewSkillDimensionRowState extends State<NewSkillDimensionRow> {
  final TextEditingController _controller = TextEditingController();

  Future<void> _add() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await widget.state.addSkillDimension(text);
    _controller.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DecomposedCourseDesignerCard.buildHeader('Add new dimension'),
        DecomposedCourseDesignerCard.buildBody(
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: CustomUiConstants.getFilledInputDecoration(
                      context,
                      labelText: 'Dimension name',
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
        ),
        DecomposedCourseDesignerCard.buildFooter(bottomMargin: 16),
      ],
    );
  }
}
