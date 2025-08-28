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
    return const WillPopScope(
      onWillPop: () async => false,
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
