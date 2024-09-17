import 'package:flutter/material.dart';

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
      throw ArgumentError('Progress must be between 0 and 1');
    }

    // Find the index of the color that corresponds to the progress
    double colorIndex = (colors.length - 1) * proficiency;

    // Determine the lower and upper bounds
    int lowerIndex = colorIndex.floor();
    int upperIndex = colorIndex.ceil();

    // Calculate the interpolation factor
    double interpolationFactor = (colorIndex - lowerIndex) * (colors.length - 1);

    // Interpolate between the two colors
    Color lowerColor = colors[lowerIndex];
    Color upperColor = colors[upperIndex];
    return Color.lerp(lowerColor, upperColor, interpolationFactor)!;
  }
}
