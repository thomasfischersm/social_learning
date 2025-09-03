import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:social_learning/data/skill_assessment.dart';
import 'package:social_learning/data/user.dart' as model;
import 'package:social_learning/ui_foundation/helper_widgets/custom_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/user_profile_widgets/profile_image_widget_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/user_profile_widgets/radar_widget.dart';

/// Card displaying a user's skill assessment with history controls.
class SkillAssessmentViewHeaderCard extends StatelessWidget {
  final model.User student;
  final List<SkillAssessment> assessments;
  final int currentIndex;
  final Map<String, model.User> instructors;
  final ValueChanged<int> onIndexChanged;

  const SkillAssessmentViewHeaderCard({
    super.key,
    required this.student,
    required this.assessments,
    required this.currentIndex,
    required this.instructors,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    final assessment = assessments[currentIndex];
    final instructor = instructors[assessment.instructorUid];
    return CustomCard(
      title: 'Skill Assessment for ${student.displayName}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProfileImageWidgetV2.fromUser(student, maxRadius: 40),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  student.displayName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.maxWidth;
              return RadarWidget(
                assessment: assessment,
                size: size,
                showLabels: true,
                drawPolygon: true,
                fillColor: Colors.blue.withOpacity(0.3),
              );
            },
          ),
          if (assessments.length > 1)
            Slider(
              value: currentIndex.toDouble(),
              min: 0,
              max: (assessments.length - 1).toDouble(),
              divisions: assessments.length - 1,
              onChanged: (v) => onIndexChanged(v.round()),
            ),
          const SizedBox(height: 8),
          Text(
            '${DateFormat.yMMMd().format(assessment.createdAt.toDate())} - '
            '${instructor?.displayName ?? ''}',
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black54),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              (assessment.notes ?? '').isEmpty
                  ? 'No notes'
                  : assessment.notes!,
            ),
          ),
        ],
      ),
    );
  }
}

