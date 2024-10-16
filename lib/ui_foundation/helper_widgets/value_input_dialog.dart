import 'package:flutter/material.dart';

class ValueInputDialog extends StatelessWidget {
  final String title;
  final String currentValue;
  final String hintText;
  final String okButtonLabel;
  final String? Function(String?)? validate;
  final Function(String) onConfirm;

  const ValueInputDialog(this.title, this.currentValue, this.hintText,
      this.okButtonLabel, this.validate, this.onConfirm,
      {super.key});

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
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  hintText: hintText,
                  errorText: errorMessage,
                ),
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
