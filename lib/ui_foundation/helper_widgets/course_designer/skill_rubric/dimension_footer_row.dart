import 'package:flutter/material.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/decomposed_course_designer_card.dart';
import 'skill_rubric_row.dart';

class DimensionFooterRow extends StatelessWidget implements SkillRubricRow {
  final String dimensionId;
  const DimensionFooterRow({super.key, required this.dimensionId});

  @override
  String get pageKey => 'footer-$dimensionId';

  @override
  Widget build(BuildContext context) {
    return DecomposedCourseDesignerCard.buildFooter(bottomMargin: 16);
  }
}
