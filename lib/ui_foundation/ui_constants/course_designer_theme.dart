import 'package:flutter/material.dart';

class CourseDesignerTheme {
  /// Default border radius used for Course Designer cards.
  static const double cardBorderRadius = 8.0;

  /// Margin applied around Course Designer cards.
  static const EdgeInsets cardMargin = EdgeInsets.only(top: 12.0);

  /// Background color for card headers.
  static final Color cardHeaderBackgroundColor = Colors.grey[100]!;

  /// Border color used around cards.
  static final Color cardBorderColor = Colors.grey.shade300;

  static const EdgeInsets cardHeaderPadding =
      EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);

  static const TextStyle cardHeaderTextStyle =
      TextStyle(fontSize: 16, fontWeight: FontWeight.bold);

  /// Padding used for content inside Course Designer cards.
  static const EdgeInsets cardBodyPadding = EdgeInsets.all(16.0);

  /// Padding for body sections built with [DecomposedCourseDesignerCard].
  static const EdgeInsets decomposedBodyPadding =
      EdgeInsets.fromLTRB(16, 0, 16, 0);

  /// Padding applied to tag pill widgets.
  static const EdgeInsets tagPillPadding =
      EdgeInsets.symmetric(horizontal: 8, vertical: 4);

  /// Border radius used for tag pill widgets.
  static const double tagPillBorderRadius = 20.0;

  /// Default text style for tag pill labels.
  static const TextStyle tagPillTextStyle =
      TextStyle(fontSize: 11, height: 1, fontWeight: FontWeight.w500);
}
