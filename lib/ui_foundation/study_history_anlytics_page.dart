import 'dart:collection';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/practice_record.dart';
import 'package:social_learning/state/course_analytics_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/instructor_dashboard/instructor_dashboard_app_bar.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Study History Analytics',
                style: CustomTextStyles.subHeadline,
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<_DayDataRow>>(
                future: _buildData(context),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    return _buildEmptyChartState();
                  }

                  return _buildChart(context, snapshot.data!);
                },
              ),
            ],
          ),
          enableCourseLoadingGuard: true,
          enableCreatorGuard: true,
          enableCourseAnalyticsGuard: true,
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context, List<_DayDataRow> rows) {
    final config = _ChartConfig.from(context, rows);

    return AspectRatio(
      aspectRatio: 1.4,
      child: LineChart(
        _buildLineChartData(context, rows, config),
      ),
    );
  }

  Widget _buildEmptyChartState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Text('No analytics available yet'),
    );
  }

  LineChartData _buildLineChartData(
    BuildContext context,
    List<_DayDataRow> rows,
    _ChartConfig config,
  ) {
    return LineChartData(
      minX: 0,
      maxX: rows.length <= 1 ? 1 : (rows.length - 1).toDouble(),
      minY: 0,
      maxY: config.adjustedMaxY,
      gridData: _buildGridData(context, config.leftInterval),
      titlesData: _buildTitlesData(rows, config),
      borderData: _buildBorderData(context),
      lineTouchData: _buildTouchData(context, rows, config),
      lineBarsData: _buildLineBarsData(config),
      betweenBarsData: _buildBetweenBarsData(config),
    );
  }

  FlGridData _buildGridData(BuildContext context, double interval) {
    final theme = Theme.of(context);
    return FlGridData(
      drawVerticalLine: false,
      horizontalInterval: interval,
      getDrawingHorizontalLine: (value) => FlLine(
        color: theme.dividerColor.withOpacity(0.2),
        strokeWidth: 1,
      ),
    );
  }

  FlTitlesData _buildTitlesData(List<_DayDataRow> rows, _ChartConfig config) {
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: _buildBottomAxisTitles(rows, config),
      leftTitles: _buildLeftAxisTitles(config),
    );
  }

  AxisTitles _buildBottomAxisTitles(
    List<_DayDataRow> rows,
    _ChartConfig config,
  ) {
    final dateFormat = DateFormat.Md();
    return AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        interval: config.bottomInterval,
        reservedSize: 48,
        getTitlesWidget: (value, meta) {
          final index = value.round();
          if (index < 0 || index >= rows.length) {
            return const SizedBox.shrink();
          }

          return SideTitleWidget(
            meta: meta,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                dateFormat.format(rows[index].day),
                style: config.axisLabelStyle,
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      ),
    );
  }

  AxisTitles _buildLeftAxisTitles(_ChartConfig config) {
    return AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        interval: config.leftInterval,
        reservedSize: 48,
        getTitlesWidget: (value, meta) {
          if (value < 0) {
            return const SizedBox.shrink();
          }

          return SideTitleWidget(
            space: 8,
            meta: meta,
            child: Text(
              value.toInt().toString(),
              style: config.axisLabelStyle,
            ),
          );
        },
      ),
    );
  }

  FlBorderData _buildBorderData(BuildContext context) {
    final theme = Theme.of(context);
    return FlBorderData(
      show: true,
      border: Border(
        bottom: BorderSide(color: theme.dividerColor),
        left: BorderSide(color: theme.dividerColor),
        right: const BorderSide(color: Colors.transparent),
        top: const BorderSide(color: Colors.transparent),
      ),
    );
  }

  LineTouchData _buildTouchData(
    BuildContext context,
    List<_DayDataRow> rows,
    _ChartConfig config,
  ) {
    final theme = Theme.of(context);
    final tooltipStyle = config.axisLabelStyle ??
        Theme.of(context).textTheme.bodySmall ??
        const TextStyle(fontSize: 12);
    final dateFormat = DateFormat.yMMMd();

    return LineTouchData(
      handleBuiltInTouches: true,
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (touchedSpot) =>
            theme.colorScheme.surfaceContainerHighest.withOpacity(0.95),
        getTooltipItems: (touchedSpots) {
          if (touchedSpots.isEmpty) {
            return [];
          }

          return touchedSpots.map((spot) {
            final index = spot.x.toInt().clamp(0, rows.length - 1);
            final row = rows[index];
            final dateLabel = dateFormat.format(row.day);

            if (spot.barIndex == 0) {
              return LineTooltipItem(
                '$dateLabel\nGraduated: ${row.graduationCount}',
                tooltipStyle,
              );
            }

            return LineTooltipItem(
              '$dateLabel\nPracticed: ${row.practiceCount}\nGraduated: ${row.graduationCount}',
              tooltipStyle,
            );
          }).toList();
        },
      ),
    );
  }

  List<LineChartBarData> _buildLineBarsData(_ChartConfig config) {
    return [
      LineChartBarData(
        spots: config.graduationSpots,
        isCurved: false,
        barWidth: 2,
        color: Colors.transparent,
        belowBarData: BarAreaData(
          show: true,
          color: config.graduationColor,
        ),
        dotData: const FlDotData(show: false),
      ),
      LineChartBarData(
        spots: config.totalSpots,
        isCurved: false,
        barWidth: 2,
        color: Colors.transparent,
        dotData: const FlDotData(show: false),
      ),
    ];
  }

  List<BetweenBarsData> _buildBetweenBarsData(_ChartConfig config) {
    return [
      BetweenBarsData(
        fromIndex: 0,
        toIndex: 1,
        color: config.practiceColor,
      ),
    ];
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

class _ChartConfig {
  _ChartConfig({
    required this.graduationSpots,
    required this.totalSpots,
    required this.adjustedMaxY,
    required this.leftInterval,
    required this.bottomInterval,
    required this.graduationColor,
    required this.practiceColor,
    required this.axisLabelStyle,
  });

  final List<FlSpot> graduationSpots;
  final List<FlSpot> totalSpots;
  final double adjustedMaxY;
  final double leftInterval;
  final double bottomInterval;
  final Color graduationColor;
  final Color practiceColor;
  final TextStyle? axisLabelStyle;

  factory _ChartConfig.from(BuildContext context, List<_DayDataRow> rows) {
    final theme = Theme.of(context);
    final axisLabelStyle = CustomTextStyles.getBodySmall(context);

    final graduationSpots = <FlSpot>[];
    final totalSpots = <FlSpot>[];
    for (int index = 0; index < rows.length; index++) {
      final row = rows[index];
      final x = index.toDouble();
      graduationSpots.add(FlSpot(x, row.graduationCount.toDouble()));
      totalSpots.add(FlSpot(x, row.totalCount.toDouble()));
    }

    final rawMaxY = totalSpots
        .map((spot) => spot.y)
        .fold<double>(0, (previous, element) => math.max(previous, element));
    final maxY = rawMaxY < 0 ? 0.0 : rawMaxY;
    final adjustedMaxY = maxY == 0 ? 1.0 : maxY * 1.1;
    final leftInterval =
        adjustedMaxY <= 4 ? 1.0 : (adjustedMaxY / 4).ceilToDouble();

    final bottomInterval = rows.length <= 1
        ? 1.0
        : math.max(1, (rows.length / 6).ceil()).toDouble();

    final graduationColor = theme.colorScheme.primary
        .withOpacity(theme.brightness == Brightness.dark ? 0.5 : 0.7);
    final practiceColor = theme.colorScheme.secondary
        .withOpacity(theme.brightness == Brightness.dark ? 0.45 : 0.55);

    return _ChartConfig(
      graduationSpots: graduationSpots,
      totalSpots: totalSpots,
      adjustedMaxY: adjustedMaxY,
      leftInterval: leftInterval,
      bottomInterval: bottomInterval,
      graduationColor: graduationColor,
      practiceColor: practiceColor,
      axisLabelStyle: axisLabelStyle,
    );
  }
}
