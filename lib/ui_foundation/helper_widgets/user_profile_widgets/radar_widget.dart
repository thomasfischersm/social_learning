import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/skill_assessment.dart';
import 'package:social_learning/data/skill_rubric.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/data/data_helpers/skill_rubrics_functions.dart';
import 'package:social_learning/state/library_state.dart';

class RadarWidget extends StatelessWidget {
  final User? user;
  final SkillAssessment? assessment;
  final List<SkillAssessmentDimension>? dimensions;
  final double size;
  final Color mainColor;
  final double mainLineWidth;
  final Color supportColor;
  final double supportLineWidth;
  final bool showLabels;
  final bool drawPolygon;
  final Color fillColor;

  const RadarWidget({
    super.key,
    this.user,
    this.assessment,
    this.dimensions,
    this.size = 200,
    this.mainColor = Colors.blue,
    this.mainLineWidth = 2,
    this.supportColor = Colors.grey,
    this.supportLineWidth = 1,
    this.showLabels = true,
    this.drawPolygon = true,
    this.fillColor = Colors.transparent,
  }) : assert(user != null || assessment != null || dimensions != null,
            'Provide user, assessment, or dimensions');

  @override
  Widget build(BuildContext context) {
    List<SkillAssessmentDimension>? dims = dimensions;
    bool polygon = drawPolygon;

    if (dims == null) {
      if (assessment != null) {
        dims = assessment!.dimensions;
      } else if (user != null) {
        final course = context.watch<LibraryState>().selectedCourse;
        if (course == null) {
          return SizedBox(width: size, height: size);
        }
        final userAssessment = user!.getCourseSkillAssessment(course);
        if (userAssessment != null) {
          dims = userAssessment.dimensions;
        } else {
          return FutureBuilder<SkillRubric?>(
            future: SkillRubricsFunctions.loadForCourse(course.id!),
            builder: (context, snapshot) {
              final rubric = snapshot.data;
              final empty = rubric?.dimensions
                      .map(
                        (d) => SkillAssessmentDimension(
                          id: d.id,
                          name: d.name,
                          degree: 0,
                          maxDegrees: d.degrees.length,
                        ),
                      )
                      .toList() ??
                  [];
              return CustomPaint(
                size: Size.square(size),
                painter: _RadarPainter(
                  dimensions: empty,
                  mainColor: mainColor,
                  mainLineWidth: mainLineWidth,
                  supportColor: supportColor,
                  supportLineWidth: supportLineWidth,
                  showLabels: showLabels,
                  drawPolygon: false,
                  fillColor: fillColor,
                ),
              );
            },
          );
        }
      }
    }

    dims ??= [];
    return CustomPaint(
      size: Size.square(size),
      painter: _RadarPainter(
        dimensions: dims!,
        mainColor: mainColor,
        mainLineWidth: mainLineWidth,
        supportColor: supportColor,
        supportLineWidth: supportLineWidth,
        showLabels: showLabels,
        drawPolygon: polygon,
        fillColor: fillColor,
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final List<SkillAssessmentDimension> dimensions;
  final Color mainColor;
  final double mainLineWidth;
  final Color supportColor;
  final double supportLineWidth;
  final bool showLabels;
  final bool drawPolygon;
  final Color fillColor;

  _RadarPainter({
    required this.dimensions,
    required this.mainColor,
    required this.mainLineWidth,
    required this.supportColor,
    required this.supportLineWidth,
    required this.showLabels,
    required this.drawPolygon,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final supportPaint = Paint()
      ..color = supportColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = supportLineWidth;
    final mainPaint = Paint()
      ..color = mainColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = mainLineWidth;

    canvas.drawCircle(center, radius, supportPaint);

    final count = dimensions.length;
    if (count == 0) {
      return;
    }

    final angleStep = 2 * pi / count;
    final path = Path();
    final labelStyle = TextStyle(color: supportColor, fontSize: 12);

    for (var i = 0; i < count; i++) {
      final angle = -pi / 2 + angleStep * i;
      final dir = Offset(cos(angle), sin(angle));

      final end = center + dir * radius;
      canvas.drawLine(center, end, supportPaint);

      final dim = dimensions[i];
      final ratio = (dim.maxDegrees == 0)
          ? 0.0
          : dim.degree.clamp(0, dim.maxDegrees).toDouble() / dim.maxDegrees;
      final point = center + dir * radius * ratio;
      if (drawPolygon) {
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }

      if (showLabels) {
        final maxLabelWidth = radius - 4;
        final tp = TextPainter(
          text: TextSpan(text: dim.name, style: labelStyle),
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '…',
        )..layout(maxWidth: maxLabelWidth);

        final labelRadius = radius - 4;
        final labelPos = center + dir * labelRadius;
        final angleDeg = angle * 180 / pi;
        var rotation = angle;
        final flip = angleDeg >= 90 && angleDeg <= 270;
        if (flip) {
          rotation += pi;
        }

        canvas.save();
        canvas.translate(labelPos.dx, labelPos.dy);
        canvas.rotate(rotation);
        canvas.translate(flip ? 0 : -tp.width, -tp.height);
        tp.paint(canvas, Offset.zero);
        canvas.restore();
      }
    }

    if (drawPolygon) {
      path.close();
      if (fillColor.alpha != 0) {
        final fillPaint = Paint()
          ..color = fillColor
          ..style = PaintingStyle.fill;
        canvas.drawPath(path, fillPaint);
      }
      canvas.drawPath(path, mainPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) {
    return old.dimensions != dimensions ||
        old.mainColor != mainColor ||
        old.mainLineWidth != mainLineWidth ||
        old.supportColor != supportColor ||
        old.supportLineWidth != supportLineWidth ||
        old.showLabels != showLabels ||
        old.drawPolygon != drawPolygon ||
        old.fillColor != fillColor;
  }
}

