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

    return CustomCard(
      title: widget.dimension.name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: widget.dimension.degrees.map((degree) {
              final isAssessment = degree.degree == widget.selectedDegree;
              final isViewing = degree.degree == _viewedDegree;
              Color? background;
              Color? foreground;
              if (isAssessment) {
                background = Theme.of(context).colorScheme.primary;
                foreground = Colors.white;
              } else if (isViewing) {
                background = Theme.of(context).colorScheme.primary.withOpacity(0.1);
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
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black54),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(selected.description ?? ''),
          ),
        ],
      ),
    );
  }
}
