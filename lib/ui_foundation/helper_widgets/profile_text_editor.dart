import 'package:flutter/material.dart';
import 'package:social_learning/data/data_helpers/user_functions.dart';
import 'package:social_learning/state/application_state.dart';

class ProfileTextEditor extends StatefulWidget {
  final ApplicationState _applicationState;

  const ProfileTextEditor(this._applicationState, {super.key});

  @override
  _ProfileTextEditorState createState() => _ProfileTextEditorState();
}

class _ProfileTextEditorState extends State<ProfileTextEditor>
    with SingleTickerProviderStateMixin {
  static const int defaultVisibleLines = 5;
  bool _isExpanded = false;
  bool _isEditing = false;
  bool _isTruncated = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _profileText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _enterEditMode() {
    setState(() {
      _isEditing = true;
    });
  }

  void _saveProfileText() {
    setState(() {
      UserFunctions.updateProfileText(
          widget._applicationState, _controller.text);
      _isEditing = false;
    });
  }

  void _cancelEditing() {
    setState(() {
      _controller.text = _profileText; // revert changes
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool hasProfileText = _profileText.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          alignment: Alignment.topLeft,
          child: _isEditing
              ? TextField(
                  controller: _controller,
                  maxLines: null, // allow multiple lines
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Edit your profile',
                  ),
                )
              : LayoutBuilder(builder: (context, constraints) {
                  _checkIfTextIsTruncated(constraints.maxWidth);
                  return Text(
                    hasProfileText
                        ? _profileText
                        : 'Write a brief profile about your learning journey. Tell others about your skills and preferences. Share your availability and interest in teaching/learning!',
                    overflow: _isExpanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                    maxLines: _isExpanded ? null : defaultVisibleLines,
                    style: hasProfileText
                        ? const TextStyle(fontSize: 16)
                        : const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic),
                  );
                }),
        ),
        const SizedBox(height: 8),
        if (_isEditing)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _cancelEditing,
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _saveProfileText,
                child: const Text('Save'),
              ),
            ],
          )
        else
          Row(
            mainAxisAlignment: _isTruncated
                ? MainAxisAlignment.spaceBetween
                : MainAxisAlignment.end,
            children: [
              if (_isTruncated)
                TextButton(
                  onPressed: _toggleExpansion,
                  child: Text(_isExpanded ? 'Read Less' : 'Read More'),
                ),
              IconButton(
                icon: const Icon(Icons.edit,color: Colors.grey,),
                onPressed: _enterEditMode,
              ),
            ],
          ),
      ],
    );
  }

  String get _profileText =>
      widget._applicationState.currentUser?.profileText.trim() ?? '';

  void _checkIfTextIsTruncated(double maxWidth) {
    final textPainter = TextPainter(
      text: TextSpan(text: _profileText, style: const TextStyle(fontSize: 16)),
      maxLines: defaultVisibleLines,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(maxWidth: maxWidth);

    if (_isTruncated != textPainter.didExceedMaxLines) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        setState(() => _isTruncated = textPainter.didExceedMaxLines);
      });
    }
    print(
        'Text is truncated: $_isTruncated, exceed max lines ${textPainter.didExceedMaxLines}, max width: $maxWidth');
  }
}
