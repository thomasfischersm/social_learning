import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/course_create_page.dart';
import 'package:social_learning/ui_foundation/helper_widgets/value_input_dialog.dart';
import 'package:social_learning/ui_foundation/ui_constants/whatsapp_util.dart';

class EditWhatsappLinkDialog extends StatelessWidget {
  final String currentCode;

  const EditWhatsappLinkDialog({super.key, required this.currentCode});

  @override
  Widget build(BuildContext context) {
    final libraryState = Provider.of<LibraryState>(context, listen: false);

    return ValueInputDialog(
      'Edit Whatsapp invitation link',
      currentCode,
      'Whatsapp link',
      'OK',
      (value) {
        value = value?.trim();
        if (value != null &&
            value.isNotEmpty &&
            !WhatsappUtil.isWhatsappLinkValid(value)) {
          return 'It doesn\'t look like a valid Whatsapp URL.';
        }
        return null;
      },
      (newLink) {
        libraryState.updateWhatsappLink(newLink.trim());
      },
    );
  }
}
