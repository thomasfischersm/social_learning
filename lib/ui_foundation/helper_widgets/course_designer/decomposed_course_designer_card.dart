import 'package:flutter/material.dart';

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
        style: const TextStyle(fontWeight: FontWeight.bold),
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

  static Widget buildFooter() {
    return Container(
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
