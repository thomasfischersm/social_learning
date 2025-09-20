import 'package:flutter/material.dart';
import 'package:social_learning/data/skill_assessment.dart';
import 'package:social_learning/data/user.dart' as model;
import 'package:social_learning/ui_foundation/helper_widgets/custom_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/user_profile_widgets/profile_image_widget_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/user_profile_widgets/radar_widget.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';

/// Top card for the skill assessment page containing profile photo,
/// prior assessment radar, current assessment radar, and notes field.
class SkillAssessmentHeaderCard extends StatelessWidget {
  final model.User student;
  final SkillAssessment? latestAssessment;
  final List<SkillAssessmentDimension> currentDimensions;
  final TextEditingController notesController;

  const SkillAssessmentHeaderCard({
    super.key,
    required this.student,
    required this.latestAssessment,
    required this.currentDimensions,
    required this.notesController,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      title: 'Create a skill assessment for ${student.displayName}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final itemSize = (constraints.maxWidth - 8) / 2.5;
              return Row(
                children: [
                  SizedBox(
                    width: itemSize / 2,
                    height: itemSize,
                    child: Center(
                        child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ProfileImageWidgetV2.fromUser(
                          student,
                          maxRadius: itemSize / 2 / 2,
                        ),
                        Text(student.displayName,
                            overflow: TextOverflow.ellipsis)
                      ],
                    )),
                  ),
                  SizedBox(width: 4),
                  SizedBox(
                    width: itemSize,
                    height: itemSize,
                    child: Center(
                      child: latestAssessment != null
                          ? RadarWidget(
                              assessment: latestAssessment!,
                              size: itemSize,
                              showLabels: true,
                              drawPolygon: true,
                              fillColor: Colors.blue.withOpacity(0.3),
                            )
                          : const Text(
                              'No prior\nassessment',
                              textAlign: TextAlign.center,
                            ),
                    ),
                  ),
                  SizedBox(width: 4),
                  SizedBox(
                    width: itemSize,
                    height: itemSize,
                    child: Center(
                      child: RadarWidget(
                        dimensions: currentDimensions,
                        size: itemSize,
                        showLabels: true,
                        drawPolygon: true,
                        fillColor: Colors.blue.withOpacity(0.3),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          TextField(
            style: CustomTextStyles.getBodyNote(context),
            controller: notesController,
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'Great progress on the weight transfers. Focusing on partner connection next will give you the most benefit.',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
