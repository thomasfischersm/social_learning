import 'package:flutter/material.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';

class ExpandingTextBox extends StatefulWidget {
  final String text;
  final int defaultVisibleLines;

  const ExpandingTextBox(this.text, this.defaultVisibleLines, {super.key});

  @override
  ExpandingTextBoxState createState() => ExpandingTextBoxState();
}

class ExpandingTextBoxState extends State<ExpandingTextBox>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isTruncated = false;

  @override
  void initState() {
    super.initState();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          alignment: Alignment.topLeft,
          child: LayoutBuilder(builder: (context, constraints) {
            _checkIfTextIsTruncated(constraints.maxWidth);
            return Text(
              widget.text,
              overflow:
                  _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              maxLines: _isExpanded ? null : widget.defaultVisibleLines,
              style: CustomTextStyles.getBody(context),
            );
          }),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (_isTruncated)
              TextButton(
                onPressed: _toggleExpansion,
                child: Text(_isExpanded ? 'Read Less' : 'Read More'),
              ),
          ],
        ),
      ],
    );
  }

  void _checkIfTextIsTruncated(double maxWidth) {
    final textPainter = TextPainter(
      text: TextSpan(text: widget.text, style: const TextStyle(fontSize: 16)),
      maxLines: widget.defaultVisibleLines,
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
