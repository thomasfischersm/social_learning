import 'package:flutter/material.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';

  class TagPill extends StatelessWidget {
    final String label;
    final Color color;

    const TagPill({
      super.key,
      required this.label,
      required this.color,
    });

    @override
    Widget build(BuildContext context) {
      final textColor = _getContrastingTextColor(color);

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: CustomTextStyles.getBodyTiny(context)?.copyWith(
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      );
    }

    Color _getContrastingTextColor(Color background) {
      return background.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    }
  }
