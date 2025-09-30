import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/practice_record.dart';
import 'package:social_learning/state/course_analytics_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/instructor_dashboard/instructor_dashboard_app_bar.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

class StudentPopulationAnalyticsPage extends StatelessWidget {
  const StudentPopulationAnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const InstructorDashboardAppBar(
        currentNav: NavigationEnum.studentPopulationAnalytics,
        title: 'Student Population Analytics',
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

  Future<List<_LessonDataRow>> _buildData(BuildContext context) async {
    LibraryState libraryState = context.watch<LibraryState>();
    CourseAnalyticsState courseAnalyticsState =
        context.watch<CourseAnalyticsState>();

    List<Lesson> lessons = libraryState.lessons ?? [];
    UnmodifiableListView<PracticeRecord> practiceRecords =
        await courseAnalyticsState.getPracticeRecords();

    List<_LessonDataRow> rows =
        lessons.map((lesson) => _LessonDataRow(lesson)).toList();
    Map<String, _LessonDataRow> lessonIdToRow = {
      for (var row in rows) row.lesson.id!: row
    };

    for (PracticeRecord record in practiceRecords) {
      var lessonId = record.lessonId.id;
      if (record.isGraduation == true) {
        lessonIdToRow[lessonId]?.graduationCount++;
      } else {
        lessonIdToRow[lessonId]?.practiceCount++;
      }
    }

    return rows;
  }

  Widget _buildUi(BuildContext context, List<_LessonDataRow> rows) {
    return Column(
      children: [
        Text('Student Population Analytics',
            style: CustomTextStyles.subHeadline),
        _buildChart(context, rows),
      ],
    );
  }

  /// Builds a line chart where the x-axis is the lessons (in order) and the
  /// y-axis is the number of students that have practiced/graduated that
  /// lesson. The graduated count should be a solid area. The practice count
  /// should be on top of the graduated count as another solid area.
  Widget _buildChart(BuildContext context, List<_LessonDataRow> rows) {
    // TODO
  }
}

class _LessonDataRow {
  final Lesson lesson;
  int graduationCount = 0;
  int practiceCount = 0;

  int get totalCount => graduationCount + practiceCount;

  _LessonDataRow(this.lesson);
}
