import 'package:flutter/material.dart';
import 'package:social_learning/data/skill_rubric.dart';
import 'package:social_learning/ui_foundation/helper_widgets/custom_card.dart';

/// Displays a skill dimension with degree buttons and shows the description of
/// the currently selected degree. The degree that was part of the assessment is
/// highlighted most strongly.
class SkillDimensionViewCard extends StatefulWidget {
  final SkillDimension dimension;
  final int selectedDegree;

  const SkillDimensionViewCard({
    super.key,
    required this.dimension,
    required this.selectedDegree,
  });

  @override
  State<SkillDimensionViewCard> createState() => _SkillDimensionViewCardState();
}

class _SkillDimensionViewCardState extends State<SkillDimensionViewCard> {
  late int _viewedDegree;

  @override
  void initState() {
    super.initState();
    _viewedDegree = widget.selectedDegree;
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.dimension.degrees.firstWhere(
      (d) => d.degree == _viewedDegree,
      orElse: () => widget.dimension.degrees.first,
    );

    final dimensionDescription = widget.dimension.description;
    final hasDimensionDescription =
        dimensionDescription != null && dimensionDescription.trim().isNotEmpty;

    return CustomCard(
      title: widget.dimension.name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasDimensionDescription) ...[
            const SizedBox(height: 2),
            _buildDescriptionBox(
              dimensionDescription,
              label: 'Dimension description',
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: widget.dimension.degrees.map((degree) {
              final isAssessment = degree.degree == widget.selectedDegree;
              final isViewing = degree.degree == _viewedDegree;
              Color? background;
              Color? foreground;
              TextStyle textStyle = Theme.of(context).textTheme.bodySmall!;
              if (isAssessment) {
                background = Theme.of(context).colorScheme.primary;
                foreground = Colors.white;
                textStyle = textStyle.copyWith(color:foreground);
              } else if (isViewing) {
                background = Theme.of(context).colorScheme.primary.withOpacity(0.2);
              }
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: background,
                      foregroundColor: foreground,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _viewedDegree = degree.degree;
                      });
                    },
                    child: Text(
                      degree.name,
                      style: textStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          _buildDescriptionBox(
            selected.description,
            label: 'Degree description',
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionBox(
    String? text, {
    required String label,
  }) {
    final value = text ?? '';
    return SizedBox(
      width: double.infinity,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        isEmpty: value.trim().isEmpty,
        child: Text(value),
      ),
    );
  }
}
