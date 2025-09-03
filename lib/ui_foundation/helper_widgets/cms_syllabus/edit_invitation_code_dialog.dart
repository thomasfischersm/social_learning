import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/value_input_dialog.dart';

class EditInvitationCodeDialog extends StatelessWidget {
  final String currentCode;

  const EditInvitationCodeDialog({super.key, required this.currentCode});

  @override
  Widget build(BuildContext context) {
    final libraryState = Provider.of<LibraryState>(context, listen: false);

    return ValueInputDialog(
      'Edit invitation code',
      currentCode,
      'Invitation code',
      'OK',
      (value) {
        if (value == null || value.trim().length < 3) {
          return 'Code must be at least 3 characters';
        }
        if (libraryState.availableCourses.any((course) =>
            (course.invitationCode ?? '').toLowerCase() ==
                value.trim().toLowerCase() &&
            course.id != libraryState.selectedCourse?.id)) {
          return 'Invitation code already exists';
        }
        return null;
      },
      (newCode) {
        libraryState.updateInvitationCode(newCode.trim());
      },
    );
  }
}
