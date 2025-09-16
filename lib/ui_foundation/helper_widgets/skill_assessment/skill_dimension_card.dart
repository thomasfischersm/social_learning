import 'package:flutter/material.dart';
import 'package:social_learning/data/skill_rubric.dart';
import 'package:social_learning/ui_foundation/helper_widgets/custom_card.dart';

import 'collapsible_description.dart';

/// Card representing a single skill dimension with degree selectors and description.
class SkillDimensionCard extends StatelessWidget {
  final SkillDimension dimension;
  final int? selectedDegree;
  final int? previousDegree;
  final ValueChanged<int> onDegreeSelected;

  const SkillDimensionCard({
    super.key,
    required this.dimension,
    required this.selectedDegree,
    required this.previousDegree,
    required this.onDegreeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final selectedDegree = this.selectedDegree;
    final previousDegree = this.previousDegree;
    final isDowngrade = selectedDegree != null &&
        previousDegree != null &&
        selectedDegree < previousDegree;
    SkillDegree? selected;
    if (selectedDegree != null) {
      selected = dimension.degrees
          .firstWhere((d) => d.degree == selectedDegree);
    }

    final description = selected?.description ?? '';
    final hasDescription = description.trim().isNotEmpty;

    return CustomCard(
      title: dimension.name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: dimension.degrees.map((degree) {
              final isSelected = selectedDegree == degree.degree;
              final color = isSelected
                  ? (isDowngrade
                      ? Colors.red
                      : Theme.of(context).colorScheme.primary)
                  : null;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: isSelected ? Colors.white : null,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onPressed: () => onDegreeSelected(degree.degree),
                    child: Text(
                      degree.name,
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (isDowngrade)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Warning: student is getting a dimension downgraded.',
                style: TextStyle(color: Colors.red),
              ),
            ),
          if (hasDescription) ...[
            const SizedBox(height: 8),
            CollapsibleDescription(
              text: description,
            ),
          ],
        ],
      ),
    );
  }
}
