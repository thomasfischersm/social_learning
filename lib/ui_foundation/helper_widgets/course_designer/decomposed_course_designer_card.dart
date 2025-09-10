import 'package:flutter/material.dart';
import 'package:social_learning/ui_foundation/ui_constants/course_designer_theme.dart';

class DecomposedCourseDesignerCard {

  static Widget buildHeader(String title) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: CourseDesignerTheme.cardHeaderBackgroundColor,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(CourseDesignerTheme.cardBorderRadius)),
        border: Border.all(color: CourseDesignerTheme.cardBorderColor),
      ),
      padding: CourseDesignerTheme.cardHeaderPadding,
      child: Text(
        title,
        style: CourseDesignerTheme.cardHeaderTextStyle,
      ),
    );
  }

  static Widget buildHeaderWithIcons(
    String title,
    List<Widget> icons, {
    bool iconsRight = true,
    List<Widget> trailingIcons = const [],
  }) {
    final children = <Widget>[];

    if (iconsRight) {
      children.add(
        Expanded(
          child: Text(
            title,
            style: CourseDesignerTheme.cardHeaderTextStyle,
          ),
        ),
      );

      children.addAll(
        icons.map(
          (icon) => Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: icon,
          ),
        ),
      );
    } else {
      children.add(
        Expanded(
          child: Text(
            title,
            style: CourseDesignerTheme.cardHeaderTextStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );

      for (var icon in icons) {
        children.add(const SizedBox(width: 6));
        children.add(icon);
      }

      children.add(const Spacer());
    }

    if (trailingIcons.isNotEmpty) {
      children.addAll(
        trailingIcons.map(
          (icon) => Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: icon,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: CourseDesignerTheme.cardHeaderBackgroundColor,
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(CourseDesignerTheme.cardBorderRadius)),
        border: Border.all(color: CourseDesignerTheme.cardBorderColor),
      ),
      padding: CourseDesignerTheme.cardHeaderPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      ),
    );
  }

  static Widget buildBody(Widget bodyContent) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: CourseDesignerTheme.cardBorderColor),
          right: BorderSide(color: CourseDesignerTheme.cardBorderColor),
        ),
      ),
      padding: CourseDesignerTheme.decomposedBodyPadding,
      child: bodyContent,
    );
  }

  static Widget buildColorHighlightedBody({
    required Widget child,
    required Color color,
    String? leadingText,
    int? dragHandleIndex,
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
              _buildLeadingBox(
                leadingText,
                color,
                leadingBackgroundColor,
                dragHandleIndex,
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

  static Widget _buildLeadingBox(
    String text,
    Color color,
    Color backgroundColor,
    int? dragHandleIndex,
  ) {
    Widget box = Container(
      width: 48,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          right: BorderSide(color: color, width: 1.2),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );

    if (dragHandleIndex != null) {
      box = ReorderableDragStartListener(index: dragHandleIndex, child: box);
    }

    return box;
  }


  static Widget buildFooter({double bottomMargin = 0}) {
    return Container(
      margin: EdgeInsets.only(bottom: bottomMargin),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: CourseDesignerTheme.cardBorderColor),
          right: BorderSide(color: CourseDesignerTheme.cardBorderColor),
          bottom: BorderSide(color: CourseDesignerTheme.cardBorderColor),
          top: BorderSide.none,
        ),
        borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(CourseDesignerTheme.cardBorderRadius)),
      ),
      height: 12, // Minimal height just to apply border and corner radius
    );
  }
}
