// import 'dart:ui';

import 'package:flutter/material.dart';

class CustomTextStyles {
  static TextStyle headline = const TextStyle(fontSize: 29);
  static TextStyle subHeadline =
      const TextStyle(fontSize: 20, color: Colors.black);

  static Color partiallyLearnedColor = const Color.fromRGBO(16, 68, 54, 1);
  static Color fullyLearnedColor = const Color.fromRGBO(31, 138, 112, 1);

  static TextStyle? getBody(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge;

  static TextStyle? getBodyEmphasized(BuildContext context) => Theme.of(context)
      .textTheme
      .bodyLarge
      ?.copyWith(fontWeight: FontWeight.bold);

  static TextStyle? getBodyNote(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium;

  static TextStyle? getPartiallyLearned(BuildContext context) =>
      getBody(context)?.copyWith(color: partiallyLearnedColor);

  static TextStyle? getFullyLearned(BuildContext context) =>
      getBody(context)?.copyWith(color: fullyLearnedColor);

  static TextStyle? getLink(BuildContext context) => getBody(context)
      ?.copyWith(color: Colors.blue, decoration: TextDecoration.underline);
}
