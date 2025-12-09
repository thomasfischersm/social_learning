import 'package:flutter/material.dart';

class CircledLetterWidget extends StatelessWidget {
  final String letter;
  final TextStyle? textStyle;
  final Color? color;
  final double paddingFactor;
  final double borderWidth;

  /// paddingFactor controls how much padding exists around the letter
  /// 0.6–0.8 is typical. Larger = more circle around the text.
  const CircledLetterWidget({
    super.key,
    required this.letter,
    this.textStyle,
    this.color,
    this.paddingFactor = 0.6,
    this.borderWidth = 1,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = this.textStyle;
    final fontSize = textStyle?.fontSize ?? 14.0;

    // Circle diameter: fontSize * a multiplier
    // paddingFactor ≈ 0.6 → visually balanced
    final diameter = fontSize * (1 + paddingFactor);

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
          // color: backgroundColor ?? Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
          border: Border.all(width: borderWidth, color: color ?? Colors.black)),
      alignment: Alignment.center,
      child: Text(
        letter.toUpperCase(),
        style: textStyle?.copyWith(
          height: 1.0, // ensures no vertical extra line height
          color: color,
        ),
      ),
    );
  }
}
