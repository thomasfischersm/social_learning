import 'package:flutter/material.dart';

class TextWidthUtil {
  const TextWidthUtil._();

  static double calculateMaxWidth(
    BuildContext context,
    List<String> texts, {
    TextStyle? textStyle,
    TextDirection? textDirection,
    int lengthThresholdDelta = 2,
  }) {
    if (texts.isEmpty) {
      return 0;
    }

    final style = textStyle ?? DefaultTextStyle.of(context).style;
    final direction = textDirection ?? Directionality.of(context);

    final sortedTexts = [...texts]
      ..sort((a, b) => b.length.compareTo(a.length));

    final maxLength = sortedTexts.first.length;
    final minLengthToCheck = maxLength - lengthThresholdDelta;
    final checkedLengths = <int>{};

    double widestWidth = 0;
    for (final text in sortedTexts) {
      if (checkedLengths.length >= 3 &&
          widestWidth > 0 &&
          text.length < minLengthToCheck) {
        break;
      }

      final textPainter = TextPainter(
        text: TextSpan(text: text, style: style),
        maxLines: 1,
        textDirection: direction,
      )..layout();

      widestWidth = textPainter.width > widestWidth
          ? textPainter.width
          : widestWidth;

      checkedLengths.add(text.length);
    }

    return widestWidth;
  }
}
