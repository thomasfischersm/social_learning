import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/Level.dart';
import 'package:social_learning/state/library_state.dart';

class EditLevelTitleDialog extends StatefulWidget {
  final Level level;

  const EditLevelTitleDialog(this.level, {super.key});

  @override
  EditLevelTitleDialogState createState() => EditLevelTitleDialogState();
}

class EditLevelTitleDialogState extends State<EditLevelTitleDialog> {
  final _formKey = GlobalKey<FormState>(); // For validating the form
  final TextEditingController _controller = TextEditingController();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();

    _controller.text = widget.level.title;
  } // Validate function
  String? _validateInput(String? value) {
    if (value == null || value.trim().length < 3) {
      return 'Name must be at least 3 characters long';
    }
    if (value.trim().length > 50) {
      return 'Name must be at most 50 characters long';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Level Name'),
      content: Form(
        key: _formKey,
        onChanged: () {
          setState(() {
            _isValid = _formKey.currentState?.validate() ?? false;
          });
        },
        child: TextFormField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: 'Level Name',
            border: OutlineInputBorder(),
          ),
          validator: _validateInput, // Attach validator to the field
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Dismiss the dialog
          },
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isValid
              ? () {
            if (_formKey.currentState!.validate()) {
              widget.level.title = _controller.text;
              LibraryState libraryState = Provider.of<LibraryState>(context, listen: false);
              libraryState.updateLevel(widget.level);

              print("Saved: ${_controller.text}");
              Navigator.of(context).pop();
            }
          }
              : null, // Disable button if invalid
          child: Text('Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}