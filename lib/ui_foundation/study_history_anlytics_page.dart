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

const int _kBottomAxisLabelCount = 4;

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
                    return const SizedBox();
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
    final totals = _LegendTotals.from(rows);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLegend(context, config, totals),
        const SizedBox(height: 16),
        AspectRatio(
          aspectRatio: 1.4,
          child: BarChart(
            _buildBarChartData(context, rows, config),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(
    BuildContext context,
    _ChartConfig config,
    _LegendTotals totals,
  ) {
    final textStyle =
        CustomTextStyles.getBodySmall(context) ?? Theme.of(context).textTheme.bodySmall;

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _LegendEntry(
          color: config.graduationColor,
          label: 'Graduated',
          value: totals.graduationCount,
          textStyle: textStyle,
        ),
        _LegendEntry(
          color: config.practiceColor,
          label: 'Total taught',
          value: totals.graduationCount + totals.practiceCount,
          textStyle: textStyle,
        ),
      ],
    );
  }

  Widget _buildEmptyChartState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Text('No analytics available yet'),
    );
  }

  BarChartData _buildBarChartData(
    BuildContext context,
    List<_DayDataRow> rows,
    _ChartConfig config,
  ) {
    return BarChartData(
      alignment: rows.length <= 1
          ? BarChartAlignment.center
          : BarChartAlignment.start,
      barTouchData: _buildTouchData(context, config),
      barGroups: config.barGroups,
      maxY: config.adjustedMaxY,
      minY: 0,
      gridData: _buildGridData(context, config.leftInterval),
      titlesData: _buildTitlesData(rows, config),
      borderData: _buildBorderData(context),
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
        interval: 1,
        reservedSize: 48,
        getTitlesWidget: (value, meta) {
          final roundedValue = value.round();
          if ((value - roundedValue).abs() > 0.01) {
            return const SizedBox.shrink();
          }

          final row = config.rowsByX[roundedValue];
          if (row == null) {
            return const SizedBox.shrink();
          }

          final orderIndex = config.orderIndexByX[roundedValue] ?? 0;
          final shouldShowLabel = config.bottomLabelIndices.contains(orderIndex);
          if (!shouldShowLabel) {
            return const SizedBox.shrink();
          }

          return SideTitleWidget(
            meta: meta,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                dateFormat.format(row.day),
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

  BarTouchData _buildTouchData(
    BuildContext context,
    _ChartConfig config,
  ) {
    final theme = Theme.of(context);
    final tooltipStyle = config.axisLabelStyle ??
        Theme.of(context).textTheme.bodySmall ??
        const TextStyle(fontSize: 12);
    final dateFormat = DateFormat.yMMMd();

    return BarTouchData(
      enabled: true,
      handleBuiltInTouches: true,
      touchTooltipData: BarTouchTooltipData(
        getTooltipColor: (_) =>
            theme.colorScheme.surfaceContainerHighest.withOpacity(0.95),
        tooltipPadding: const EdgeInsets.all(8),
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          final roundedX = group.x.round();
          final row = config.rowsByX[roundedX];
          if (row == null) {
            return null;
          }
          final dateLabel = dateFormat.format(row.day);

          return BarTooltipItem(
            '$dateLabel\nPracticed: ${row.practiceCount}\nGraduated: ${row.graduationCount}',
            tooltipStyle,
          );
        },
      ),
    );
  }

  Future<List<_DayDataRow>> _buildData(BuildContext context) async {
    CourseAnalyticsState courseAnalyticsState =
        context.watch<CourseAnalyticsState>();

    UnmodifiableListView<PracticeRecord> practiceRecords =
        UnmodifiableListView(await courseAnalyticsState.getActualPracticeRecords());

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
    required this.barGroups,
    required this.adjustedMaxY,
    required this.leftInterval,
    required this.rowsByX,
    required this.orderIndexByX,
    required this.bottomLabelIndices,
    required this.axisLabelStyle,
    required this.practiceColor,
    required this.graduationColor,
  });

  final List<BarChartGroupData> barGroups;
  final double adjustedMaxY;
  final double leftInterval;
  final Map<int, _DayDataRow> rowsByX;
  final Map<int, int> orderIndexByX;
  final Set<int> bottomLabelIndices;
  final TextStyle? axisLabelStyle;
  final Color practiceColor;
  final Color graduationColor;

  factory _ChartConfig.from(BuildContext context, List<_DayDataRow> rows) {
    final theme = Theme.of(context);
    final axisLabelStyle = CustomTextStyles.getBodySmall(context);

    final graduationColor = theme.colorScheme.primary
        .withOpacity(theme.brightness == Brightness.dark ? 0.5 : 0.7);
    final practiceColor = theme.colorScheme.secondary
        .withOpacity(theme.brightness == Brightness.dark ? 0.45 : 0.55);

    final barGroups = <BarChartGroupData>[];
    final rowsByX = <int, _DayDataRow>{};
    final orderIndexByX = <int, int>{};
    double maxY = 0;
    final baseDay = rows.first.day;
    const barWidth = 8.0;
    for (int index = 0; index < rows.length; index++) {
      final row = rows[index];
      final dayOffset = row.day.difference(baseDay).inDays;
      final practiceValue = row.practiceCount.toDouble();
      final totalValue = row.totalCount.toDouble();
      maxY = math.max(maxY, totalValue);

      rowsByX[dayOffset] = row;
      orderIndexByX[dayOffset] = index;

      barGroups.add(
        BarChartGroupData(
          x: dayOffset,
          barRods: [
            BarChartRodData(
              toY: totalValue,
              rodStackItems: [
                BarChartRodStackItem(0, practiceValue, practiceColor),
                BarChartRodStackItem(
                  practiceValue,
                  totalValue,
                  graduationColor,
                ),
              ],
              borderRadius: BorderRadius.zero,
              width: barWidth,
            ),
          ],
        ),
      );
    }

    final adjustedMaxY = maxY <= 0 ? 1.0 : maxY * 1.1;
    final leftInterval =
        adjustedMaxY <= 4 ? 1.0 : (adjustedMaxY / 4).ceilToDouble();

    final bottomLabelIndices = _buildBottomLabelIndices(rows.length);

    return _ChartConfig(
      barGroups: barGroups,
      adjustedMaxY: adjustedMaxY,
      leftInterval: leftInterval,
      rowsByX: rowsByX,
      orderIndexByX: orderIndexByX,
      bottomLabelIndices: bottomLabelIndices,
      axisLabelStyle: axisLabelStyle,
      practiceColor: practiceColor,
      graduationColor: graduationColor,
    );
  }
}

Set<int> _buildBottomLabelIndices(int rowCount) {
  if (rowCount <= 0) {
    return const <int>{};
  }

  final targetLabelCount = math.min(_kBottomAxisLabelCount, rowCount);
  final indices = SplayTreeSet<int>()
    ..add(0)
    ..add(rowCount - 1);

  if (targetLabelCount <= 2) {
    return indices;
  }

  final step = (rowCount - 1) / (targetLabelCount - 1);
  for (int i = 1; i < targetLabelCount - 1; i++) {
    indices.add((i * step).round());
  }

  return indices;
}

class _LegendTotals {
  _LegendTotals({
    required this.practiceCount,
    required this.graduationCount,
  });

  final int practiceCount;
  final int graduationCount;

  factory _LegendTotals.from(List<_DayDataRow> rows) {
    var practiceTotal = 0;
    var graduationTotal = 0;

    for (final row in rows) {
      practiceTotal += row.practiceCount;
      graduationTotal += row.graduationCount;
    }

    return _LegendTotals(
      practiceCount: practiceTotal,
      graduationCount: graduationTotal,
    );
  }
}

class _LegendEntry extends StatelessWidget {
  const _LegendEntry({
    required this.color,
    required this.label,
    required this.value,
    required this.textStyle,
  });

  final Color color;
  final String label;
  final int value;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text('$label: $value', style: textStyle),
      ],
    );
  }
}
