import 'package:flutter/material.dart';
import 'package:social_learning/data/skill_assessment.dart';
import 'package:social_learning/ui_foundation/helper_widgets/custom_card.dart';

/// Displays a legacy skill dimension that no longer exists in the current rubric.
class LegacySkillDimensionViewCard extends StatelessWidget {
  final SkillAssessmentDimension dimension;

  const LegacySkillDimensionViewCard({
    super.key,
    required this.dimension,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      title: dimension.name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.info_outline),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This dimension no longer exists in the current rubric.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Degree at time of assessment: '
              '${dimension.degree}/${dimension.maxDegrees}'),
        ],
      ),
    );
  }
}

