import 'package:flutter/material.dart';

class DialogUtils {
  // This static method shows a confirmation dialog
  static Future<void> showConfirmationDialog(
    BuildContext context,
    String title,
    String body,
    VoidCallback onConfirm,
  ) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            ElevatedButton(
              child: const Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                onConfirm(); // Call the provided action
              },
            ),
          ],
        );
      },
    );
  }
}
