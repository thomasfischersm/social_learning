  import 'package:flutter/material.dart';

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
          style: TextStyle(
            fontSize: 11,
            height: 1,
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    Color _getContrastingTextColor(Color background) {
      return background.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    }
  }
