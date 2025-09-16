import 'package:flutter/material.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/library_state.dart';

class BeltColorFunctions {
  static const List<Color> colors = [
    Colors.white,
    Colors.yellow,
    Colors.orange,
    Colors.red,
    Colors.purple,
    Colors.blue,
    Colors.green,
    Colors.brown,
    Colors.black,
  ];

  static const List<Color> karateColors = [
    Colors.white,
    Colors.yellow,
    Colors.orange,
    Colors.green,
    Colors.blue,
    Colors.purple,
    Colors.brown,
    Colors.red,
    Colors.black,
  ];

  static Color getBeltColor(double proficiency) {
    // Handle edge cases
    if (proficiency < 0 || proficiency > 1) {
      throw ArgumentError(
          'Progress must be between 0 and 1 but was $proficiency');
    }

    // Find the index of the color that corresponds to the progress
    double colorIndex = (colors.length - 1) * proficiency;

    // Determine the lower and upper bounds
    int lowerIndex = colorIndex.floor();
    int upperIndex = colorIndex.ceil();

    // If the proficiency lines up exactly with a defined color, return it
    if (lowerIndex == upperIndex) {
      return colors[lowerIndex];
    }

    // Calculate the interpolation factor between the two colors.
    // The factor should be the fractional part of [colorIndex], giving a value
    // between 0 and 1 for [Color.lerp].
    final double interpolationFactor = colorIndex - lowerIndex;

    // Interpolate between the two colors
    final Color lowerColor = colors[lowerIndex];
    final Color upperColor = colors[upperIndex];
    return Color.lerp(lowerColor, upperColor, interpolationFactor)!;
  }

  static Color? getSelectedCourseBeltColor({
    required LibraryState libraryState,
    User? user,
  }) {
    if (user == null) {
      return null;
    }

    final course = libraryState.selectedCourse;
    if (course == null) {
      return null;
    }

    final proficiency = user.getCourseProficiency(course);
    if (proficiency == null) {
      return null;
    }

    return getBeltColor(proficiency.proficiency);
  }
}
