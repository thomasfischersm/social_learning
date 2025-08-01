import 'package:flutter/material.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';

class ValueInputDialog extends StatelessWidget {
  final String title;
  final String currentValue;
  final String? instructionText;
  final String hintText;
  final String okButtonLabel;
  final String? Function(String?)? validate;
  final Function(String) onConfirm;

  const ValueInputDialog(this.title, this.currentValue,
      this.hintText, this.okButtonLabel, this.validate, this.onConfirm,
      {super.key, this.instructionText});

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller =
        TextEditingController(text: currentValue);
    String? errorMessage;

    return AlertDialog(
      title: Text(title),
      content: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (instructionText != null && instructionText!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Align(alignment: Alignment.centerLeft, child:Text(instructionText!)),
                ),
              TextField(
                controller: controller,
                decoration: CustomUiConstants.getFilledInputDecoration(
                  context,
                  hintText: hintText,
                ).copyWith(errorText: errorMessage),
                onChanged: (value) {
                  // Validate and update error message dynamically
                  errorMessage = validate?.call(value);
                  setState(() {}); // Rebuild to show error message
                },
              ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(), // Cancel
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // Validate before confirming
            errorMessage = validate?.call(controller.text);
            if (errorMessage == null) {
              onConfirm(controller.text);
              Navigator.of(context).pop(); // Close dialog
            }
          },
          child: Text(okButtonLabel),
        ),
      ],
    );
  }
}
