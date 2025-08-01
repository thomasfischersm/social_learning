import 'package:flutter/material.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';

class DecomposedCourseDesignerCard {
  static const _borderRadius = 8.0;

  static Widget buildHeader(String title) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(_borderRadius)),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        title,
        style: CustomTextStyles.subHeadline,
      ),
    );
  }

  static Widget buildHeaderWithIcons(String title, List<Widget> icons) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(_borderRadius)),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: CustomTextStyles.subHeadline,
            ),
          ),
          ...icons.map((icon) => Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: icon,
              )),
        ],
      ),
    );
  }

  static Widget buildBody(Widget bodyContent) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Colors.grey.shade300),
          right: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: bodyContent,
    );
  }

  static Widget buildColorHighlightedBody({
    required BuildContext context,
    required Widget child,
    required Color color,
    String? leadingText,
  }) {
    final Color backgroundColor = color.withAlpha((0.08 * 255).round());  // subtle tint
    final Color leadingBackgroundColor = color.withAlpha((0.18 * 255).round());  // stronger tint

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: color, width: 1.2), // colored border on all sides
      ),
      // No outer margin or padding
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (leadingText != null)
              Container(
                width: 48,
                decoration: BoxDecoration(
                  color: leadingBackgroundColor,
                  border: Border(
                    right: BorderSide(color: color, width: 1.2),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  leadingText,
                  style: CustomTextStyles.getBody(context)?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }


  static Widget buildFooter({double bottomMargin = 0}) {
    return Container(
      margin: EdgeInsets.only(bottom: bottomMargin),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Colors.grey.shade300),
          right: BorderSide(color: Colors.grey.shade300),
          bottom: BorderSide(color: Colors.grey.shade300),
          top: BorderSide.none,
        ),
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(_borderRadius)),
      ),
      height: 12, // Minimal height just to apply border and corner radius
    );
  }
}
