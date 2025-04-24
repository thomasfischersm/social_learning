import 'package:flutter/material.dart';
import 'package:social_learning/data/data_helpers/instructor_dashboard_functions.dart';
import 'package:social_learning/ui_foundation/other_profile_page.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/data/user.dart';

/// Dashboard summary showing key metrics in a 2×2 grid, fetching data in parallel.
class InstructorDashboardSummaryWidget extends StatefulWidget {
  final String? courseId; // nullable: may load later
  const InstructorDashboardSummaryWidget({Key? key, this.courseId})
      : super(key: key);

  @override
  InstructorDashboardSummaryWidgetState createState() =>
      InstructorDashboardSummaryWidgetState();
}

class InstructorDashboardSummaryWidgetState
    extends State<InstructorDashboardSummaryWidget> {
  late Future<List<dynamic>> _countsFuture;

  @override
  void initState() {
    super.initState();
    _initCountsFuture();
  }

  @override
  void didUpdateWidget(covariant InstructorDashboardSummaryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If courseId has just become available or changed, re-fetch
    if (oldWidget.courseId != widget.courseId) {
      _initCountsFuture();
    }
  }

  void _initCountsFuture() {
    print('Initializing counts future with courseId: ${widget.courseId}');
    if (widget.courseId != null) {
      // Kick off all three queries in parallel
      _countsFuture = Future.wait([
        InstructorDashboardFunctions.getStudentCount(widget.courseId!),
        InstructorDashboardFunctions.getLessonCount(widget.courseId!),
        InstructorDashboardFunctions.getSessionsTaughtCount(widget.courseId!),
        InstructorDashboardFunctions.getMostAdvancedStudent(widget.courseId!),
      ]);
      print('Counts future initialized with courseId: ${widget.courseId}');
    } else {
      // No courseId yet: placeholders
      _countsFuture = Future.value([null, null, null, null]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _countsFuture,
      builder: (context, snapshot) {
        // Show dash if still loading or on error
        final stats = snapshot.data ?? [null, null, null, null];
        final studentCount = stats[0] as int?;
        final lessonCount = stats[1] as int?;
        final sessionsCount = stats[2] as int?;
        final topUser = stats[3] as User?;

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.5,
          padding: const EdgeInsets.all(8),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: [
            StatCard(
              iconData: Icons.group,
              label: 'Students',
              value: studentCount?.toString() ?? '-',
            ),
            StatCard(
              iconData: Icons.library_books,
              label: 'Lessons',
              value: lessonCount?.toString() ?? '-',
            ),
            StatCard(
              iconData: Icons.repeat,
              label: 'Sessions Taught',
              value: sessionsCount?.toString() ?? '-',
            ),
            StatCard(
              iconData: Icons.emoji_events,
              label: 'Most Advanced',
              value: topUser?.displayName ?? '-',
              onTap: topUser == null
                  ? null
                  : () {
                      OtherProfileArgument.goToOtherProfile(
                        context,
                        topUser.id,
                        topUser.uid,
                      );
                    },
            ),
          ],
        );
      },
    );
  }
}

/// A stat card with an icon background stretched to the full card height.
class StatCard extends StatelessWidget {
  final IconData iconData;
  final String label;
  final String value;
  final VoidCallback? onTap; // ← new

  const StatCard({
    Key? key,
    required this.iconData,
    required this.label,
    required this.value,
    this.onTap, // ← new
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget card = Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 48,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(iconData, color: theme.primaryColor, size: 24),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: CustomTextStyles.subHeadline,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(label, style: CustomTextStyles.getBodySmall(context)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // If onTap is provided, wrap in InkWell to show ripple and handle taps
    if (onTap != null) {
      return InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}
