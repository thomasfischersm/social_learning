import 'package:flutter/material.dart';

/// A utility dialog that shows a blocking spinner while an async
/// operation is in progress.
///
/// The dialog cannot be dismissed by the user and prevents interaction
/// with the underlying UI until [Navigator.pop] is called.
class BlockingSpinnerDialog {
  /// Displays the spinner dialog.
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _BlockingSpinner(),
    );
  }
}

class _BlockingSpinner extends StatelessWidget {
  const _BlockingSpinner();

  @override
  Widget build(BuildContext context) {
    // `PopScope` is used instead of the deprecated `WillPopScope` so that the
    // user cannot dismiss the dialog via the system back button. Setting
    // `canPop` to false ensures the route cannot be popped until the caller
    // explicitly dismisses the dialog.
    return const PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
