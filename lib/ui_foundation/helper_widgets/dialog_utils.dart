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

  static Future<void> showInfoDialog(
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
            ElevatedButton(
              child: const Text('OK'),
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

  static Future<void> showInfoDialogWithContent(
    BuildContext context,
    String title,
    Widget content, {
    VoidCallback? onConfirm,
    String confirmLabel = 'OK',
  }) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: content,
          actions: <Widget>[
            ElevatedButton(
              child: Text(confirmLabel),
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm?.call();
              },
            ),
          ],
        );
      },
    );
  }

  // This static method shows a confirmation dialog
  static Future<void> showOptionalActionDialogWithContent(
      BuildContext context,
      String title,
      String actionLabel,
      VoidCallback onAction,
      Widget content,
      ) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: content,
          actions: <Widget>[
            TextButton(
              child: const Text('Dismiss'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            ElevatedButton(
              child: Text(actionLabel),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                onAction();
              },
            ),
          ],
        );
      },
    );
  }
}
