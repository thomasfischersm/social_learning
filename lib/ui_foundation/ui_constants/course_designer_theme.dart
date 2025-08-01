import 'package:flutter/material.dart';

/// Styling helpers specific to the course designer screens.
class CourseDesignerTheme {
  /// Standard style for less prominent [ElevatedButton]s.
  static final ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.grey.shade100,
    foregroundColor: Colors.black87,
    elevation: 0,
  );
}
