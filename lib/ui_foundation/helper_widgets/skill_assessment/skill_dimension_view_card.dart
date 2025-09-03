import 'package:flutter/material.dart';
import 'package:social_learning/data/skill_rubric.dart';
import 'package:social_learning/ui_foundation/helper_widgets/custom_card.dart';

/// Displays a skill dimension with all degrees and highlights the selected one.
class SkillDimensionViewCard extends StatelessWidget {
  final SkillDimension dimension;
  final int selectedDegree;

  const SkillDimensionViewCard({
    super.key,
    required this.dimension,
    required this.selectedDegree,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      title: dimension.name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: dimension.degrees.map((deg) {
          final isSelected = deg.degree == selectedDegree;
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : null,
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.black54,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deg.name,
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (deg.description != null) ...[
                  const SizedBox(height: 4),
                  Text(deg.description!),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

