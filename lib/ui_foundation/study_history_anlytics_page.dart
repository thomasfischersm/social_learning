import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/practice_record.dart';
import 'package:social_learning/state/course_analytics_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/instructor_dashboard/instructor_dashboard_app_bar.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

class StudyHistoryAnlyticsPage extends StatelessWidget {
  const StudyHistoryAnlyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const InstructorDashboardAppBar(
        currentNav: NavigationEnum.studyHistoryAnlytics,
        title: 'Study History Analytics',
      ),
      bottomNavigationBar: BottomBarV2.build(context),
      body: Align(
        alignment: Alignment.topCenter,
        child: CustomUiConstants.framePage(
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hello World'),
            ],
          ),
          enableCourseLoadingGuard: true,
          enableCreatorGuard: true,
          enableCourseAnalyticsGuard: true,
        ),
      ),
    );
  }

  Future<List<_DayDataRow>> _buildData(BuildContext context) async {
    CourseAnalyticsState courseAnalyticsState =
        context.watch<CourseAnalyticsState>();

    UnmodifiableListView<PracticeRecord> practiceRecords =
        await courseAnalyticsState.getPracticeRecords();

    final Map<DateTime, _DayDataRow> dayToRow = {};

    for (PracticeRecord record in practiceRecords) {
      final timestamp = record.timestamp;
      if (timestamp == null) {
        continue;
      }

      final date = timestamp.toDate();
      final day = DateTime(date.year, date.month, date.day);
      final row = dayToRow.putIfAbsent(day, () => _DayDataRow(day));

      if (record.isGraduation) {
        row.graduationCount++;
      } else {
        row.practiceCount++;
      }
    }

    final rows = dayToRow.values.toList()
      ..sort((a, b) => a.day.compareTo(b.day));
    return rows;
  }
}

class _DayDataRow {
  _DayDataRow(this.day);

  final DateTime day;
  int graduationCount = 0;
  int practiceCount = 0;

  int get totalCount => graduationCount + practiceCount;
}
