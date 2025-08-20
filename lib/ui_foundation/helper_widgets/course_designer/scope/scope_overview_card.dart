import 'package:flutter/material.dart';
import 'package:social_learning/data/course_profile.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/course_designer_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/scope/course_duration_edit_dialog.dart';
import 'package:social_learning/ui_foundation/helper_widgets/course_designer/scope/scope_context.dart';
import 'package:social_learning/ui_foundation/helper_widgets/value_input_dialog.dart';

class ScopeOverviewCard extends StatefulWidget {
  final ScopeContext scopeContext;

  const ScopeOverviewCard({
    super.key,
    required this.scopeContext,
  });

  @override
  State<ScopeOverviewCard> createState() => _ScopeOverviewCardState();
}

class _ScopeOverviewCardState extends State<ScopeOverviewCard> {
  @override
  Widget build(BuildContext context) {
    final profile = widget.scopeContext.courseProfile;
    if (profile == null) {
      return const CourseDesignerCard(
        title: 'Step 4: Scope Overview',
        body: Text('Course profile data not available.'),
      );
    }

    final totalSelectedMinutes =
        widget.scopeContext.getSelectedItemsTotalMinutes();

    final totalCourseMinutes = profile.totalCourseDurationInMinutes ?? 0;
    final instructionalTargetPercent = profile.instructionalTimePercent;
    final instructionalTargetMinutes =
        totalCourseMinutes * instructionalTargetPercent / 100;
    final defaultTeachableItemDurationInMinutes =
        profile.defaultTeachableItemDurationInMinutes;

    Color barColor;
    if (instructionalTargetMinutes == 0 || totalCourseMinutes == 0) {
      barColor = Colors.grey;
    } else if (totalSelectedMinutes <= instructionalTargetMinutes * 0.95) {
      barColor = Colors.grey;
    } else if (totalSelectedMinutes <= instructionalTargetMinutes) {
      barColor = Colors.green;
    } else if (totalSelectedMinutes <= totalCourseMinutes) {
      barColor = Colors.orange;
    } else {
      barColor = Colors.red;
    }

    return CourseDesignerCard(
      title: 'Step 4: Scope Overview',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This is the difficult task of cutting what doesn'
            't fit into the course. By selecting/unselecting items, it will easily let you play around with different scenarios.',
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: _editCourseDuration,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Course duration: ${_formatDuration(totalCourseMinutes)}',
                        ),
                      ),
                      const Icon(Icons.edit, size: 18),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: _editInstructionalPercentage,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Instructional percentage: $instructionalTargetPercent%',
                        ),
                      ),
                      const Icon(Icons.edit, size: 18),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: _editDefaultTeachableItemDurationInMinutes,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Default item duration: $defaultTeachableItemDurationInMinutes min',
                        ),
                      ),
                      const Icon(Icons.edit, size: 18),
                    ],
                  ),
                ),
              ),
              Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  'Selected items duration: ${_formatDuration(totalSelectedMinutes)}',
                ),
              ),
            ],
          ),
          // const SizedBox(height: 16),
          LinearProgressIndicator(
            value: totalCourseMinutes > 0
                ? (totalSelectedMinutes / totalCourseMinutes).clamp(0.0, 1.0)
                : 0,
            backgroundColor: Colors.grey[300],
            color: barColor,
            minHeight: 10,
          ),
        ],
      ),
    );
  }

  void _editCourseDuration() {
    showDialog(
      context: context,
      builder: (context) => CourseDurationEditDialog(
        scopeContext: widget.scopeContext,
      ),
    ).then((_) {
      setState(() {}); // Refresh UI after dialog closes if needed
    });
  }

  void _editInstructionalPercentage() {
    showDialog(
      context: context,
      builder: (context) => ValueInputDialog(
        'Instructional Time (%)',
        widget.scopeContext.courseProfile?.instructionalTimePercent
                .toString() ??
            '75',
        'Example: 70. Time left is used for warm-ups, breaks, or group sharing.',
        'Save',
        (value) {
          final num = int.tryParse(value ?? '');
          if (num == null) return 'Please enter a valid number';
          if (num < 0 || num > 1000) return 'Must be between 0 and 1000';
          return null;
        },
        (newValue) {
          final newPercent = int.parse(newValue);
          widget.scopeContext.saveInstructionalPercentage(newPercent);
        },
        instructionText:
            'Note all classroom time can be used for covering new content.\n\n'
            'Time left is used for warm-ups, breaks, or group sharing.',
      ),
    );
  }

  String _formatDuration(int? minutes) {
    if (minutes == null) return '--';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours > 0 && remainingMinutes > 0) {
      return '$hours hour${hours == 1 ? '' : 's'} $remainingMinutes min';
    } else if (hours > 0) {
      return '$hours hour${hours == 1 ? '' : 's'}';
    } else {
      return '$remainingMinutes min';
    }
  }

  void _editDefaultTeachableItemDurationInMinutes() {
    showDialog(
      context: context,
      builder: (context) => ValueInputDialog(
        'Default Teachable Item Duration (min)',
        widget.scopeContext.courseProfile
                ?.defaultTeachableItemDurationInMinutes
                .toString() ??
            '15',
        'Example: 15.',
        'Save',
        (value) {
          final num = int.tryParse(value ?? '');
          if (num == null) return 'Please enter a valid number';
          if (num < 1) return 'Must be at least 1 minute';
          return null;
        },
        (newValue) {
          final newDuration = int.parse(newValue);
          widget.scopeContext.saveDefaultTeachableItemDuration(newDuration);
        },
      ),
    );
  }
}
