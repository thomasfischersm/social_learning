import 'package:flutter/material.dart';
import 'package:social_learning/ui_foundation/ui_constants/course_designer_theme.dart';

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
      padding: CourseDesignerTheme.tagPillPadding,
      decoration: BoxDecoration(
        color: color,
        borderRadius:
            BorderRadius.circular(CourseDesignerTheme.tagPillBorderRadius),
      ),
      child: Text(
        label,
        style: CourseDesignerTheme.tagPillTextStyle
            .copyWith(color: textColor),
      ),
    );
    }

    Color _getContrastingTextColor(Color background) {
      return background.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    }
  }
