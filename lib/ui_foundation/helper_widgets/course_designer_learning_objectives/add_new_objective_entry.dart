import 'package:flutter/material.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer_learning_objectives/learning_objectives_context.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';

class AddNewObjectiveEntry extends StatefulWidget {
  final LearningObjectivesContext objectivesContext;

  const AddNewObjectiveEntry({
    super.key,
    required this.objectivesContext,
  });

  @override
  State<AddNewObjectiveEntry> createState() => _AddNewObjectiveEntryState();
}

class _AddNewObjectiveEntryState extends State<AddNewObjectiveEntry> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState!;
    if (!form.validate()) return;

    final name = _controller.text.trim();
    _controller.clear();
    final currentFocus = _focusNode;
    await widget.objectivesContext.addObjective(name);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!currentFocus.hasFocus) {
        FocusScope.of(context).requestFocus(currentFocus);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
      child: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: CustomUiConstants.getFilledInputDecoration(
            context,
            labelText: 'Add new objective…',
            enabledColor: Colors.grey.shade300,
          ).copyWith(
            errorBorder: CustomUiConstants.getInputBorder(color: Colors.red),
            focusedErrorBorder:
                CustomUiConstants.getInputBorder(color: Colors.red, width: 2),
          ),
          validator: (value) {
            final trimmed = value?.trim() ?? '';
            if (trimmed.isEmpty) {
              return 'Name cannot be empty';
            }
            final exists = widget.objectivesContext.learningObjectives.any(
                  (o) => o.name.toLowerCase().trim() == trimmed.toLowerCase(),
            );
            if (exists) {
              return 'An objective with that name already exists';
            }
            return null;
          },
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
    );
  }
}
