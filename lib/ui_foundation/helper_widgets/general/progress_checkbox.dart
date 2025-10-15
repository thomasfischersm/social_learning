import 'package:flutter/material.dart';

/// A read-only checkbox that visualizes fractional progress by partially
/// filling the checkbox from right to left.
///
/// The [value] is clamped to the range `0`–`1`. A value of `0` renders an empty
/// checkbox, while `1` renders the fully checked Material checkbox. Values in
/// between fill the checkbox shell proportionally from the right edge toward
/// the left using the checkbox's active color.
class ProgressCheckbox extends StatelessWidget {
  const ProgressCheckbox({
    super.key,
    required this.value,
  });

  /// The completion value represented by the checkbox. Expected to be within
  /// `0` to `1`.
  final double value;

  @override
  Widget build(BuildContext context) {
    final double clampedValue = value.clamp(0.0, 1.0).toDouble();
    final ThemeData theme = Theme.of(context);
    final CheckboxThemeData checkboxTheme = CheckboxTheme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final bool useMaterial3 = theme.useMaterial3;

    Color resolveFillColor(Set<MaterialState> states) {
      final Color? themed = checkboxTheme.fillColor?.resolve(states);
      if (themed != null) {
        return themed;
      }
      final bool selected = states.contains(MaterialState.selected);
      if (useMaterial3) {
        if (states.contains(MaterialState.disabled)) {
          if (selected) {
            return colors.onSurface.withOpacity(0.38);
          }
          return Colors.transparent;
        }
        if (selected) {
          return colors.primary;
        }
        return Colors.transparent;
      }
      if (states.contains(MaterialState.disabled)) {
        if (selected) {
          return theme.disabledColor;
        }
        return Colors.transparent;
      }
      if (selected) {
        return colors.secondary;
      }
      return Colors.transparent;
    }

    BorderSide resolveSide(Set<MaterialState> states) {
      final BorderSide? themed = checkboxTheme.side;
      if (themed is WidgetStateBorderSide) {
        final BorderSide? resolved =
        WidgetStateProperty.resolveAs<BorderSide?>(themed, states);
        if (resolved != null) {
          return resolved;
        }
      } else if (themed != null) {
        return themed;
      }
      final bool selected = states.contains(MaterialState.selected);
      if (useMaterial3) {
        if (selected) {
          return const BorderSide(width: 0.0, color: Colors.transparent);
        }
        return BorderSide(width: 2.0, color: colors.onSurfaceVariant);
      }
      if (selected) {
        return const BorderSide(width: 2.0, color: Colors.transparent);
      }
      return BorderSide(width: 2.0, color: theme.unselectedWidgetColor);
    }

    Color resolveCheckColor(Set<MaterialState> states) {
      final Color? themed = checkboxTheme.checkColor?.resolve(states);
      if (themed != null) {
        return themed;
      }
      if (useMaterial3) {
        if (states.contains(MaterialState.disabled)) {
          if (states.contains(MaterialState.selected)) {
            return colors.surface;
          }
          return Colors.transparent;
        }
        if (states.contains(MaterialState.selected)) {
          return colors.onPrimary;
        }
        return Colors.transparent;
      }
      return const Color(0xFFFFFFFF);
    }

    final OutlinedBorder shape = checkboxTheme.shape ??
        (useMaterial3
            ? const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(2.0)),
        )
            : const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(1.0)),
        ));

    final Color activeFillColor =
    resolveFillColor(<MaterialState>{MaterialState.selected});
    final Color inactiveFillColor = resolveFillColor(<MaterialState>{});
    final BorderSide activeSide =
    resolveSide(<MaterialState>{MaterialState.selected});
    final BorderSide inactiveSide = resolveSide(<MaterialState>{});
    final Color checkColor =
    resolveCheckColor(<MaterialState>{MaterialState.selected});

    final bool isComplete = clampedValue == 1.0;
    final bool hasProgress = clampedValue > 0.0;

    return Semantics(
      checked: isComplete,
      mixed: !isComplete && hasProgress ? true : null,
      value: '${(clampedValue * 100).round()}%',
      readOnly: true,
      child: SizedBox.square(
        dimension: _kBoxSize,
        child: CustomPaint(
          painter: _ProgressCheckboxPainter(
            value: clampedValue,
            shape: shape,
            activeColor: activeFillColor,
            inactiveColor: inactiveFillColor,
            checkColor: checkColor,
            activeSide: activeSide,
            inactiveSide: inactiveSide,
          ),
        ),
      ),
    );
  }
}

const double _kBoxSize = Checkbox.width;
const double _kFillInset = 1.0;
const double _kCheckScale = 0.76;
const double _kCheckStrokeWidth = 2.4;
const Offset _kCheckStart = Offset(0.14, 0.60);
const Offset _kCheckMid = Offset(0.45, 0.80);
const Offset _kCheckEnd = Offset(0.86, 0.26);

class _ProgressCheckboxPainter extends CustomPainter {
  const _ProgressCheckboxPainter({
    required this.value,
    required this.shape,
    required this.activeColor,
    required this.inactiveColor,
    required this.checkColor,
    required this.activeSide,
    required this.inactiveSide,
  });

  final double value;
  final OutlinedBorder shape;
  final Color activeColor;
  final Color inactiveColor;
  final Color checkColor;
  final BorderSide activeSide;
  final BorderSide inactiveSide;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Path shapePath = shape.getOuterPath(rect);

    final BorderSide side = value == 1.0 ? activeSide : inactiveSide;
    final double inset = side.width / 2 + _kFillInset;
    final Rect fillBounds = Rect.fromLTWH(
      rect.left + inset,
      rect.top + inset,
      rect.width - inset * 2,
      rect.height - inset * 2,
    );

    final Color backgroundColor = value == 1.0 ? activeColor : inactiveColor;
    final Paint backgroundPaint = Paint()..color = backgroundColor;
    canvas.drawPath(shapePath, backgroundPaint);

    if (value > 0.0 && value < 1.0) {
      final double fillWidth = fillBounds.width * value;
      final Rect fillRect = Rect.fromLTWH(
        fillBounds.right - fillWidth,
        fillBounds.top,
        fillWidth,
        fillBounds.height,
      );
      final Paint fillPaint = Paint()..color = activeColor;
      canvas.save();
      canvas.clipPath(shapePath);
      canvas.drawRect(fillRect, fillPaint);
      canvas.restore();
    }

    shape.copyWith(side: side).paint(canvas, rect);

    if (value == 1.0) {
      final Paint checkPaint = Paint()
        ..color = checkColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = _kCheckStrokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final double checkEdge = size.shortestSide * _kCheckScale;
      final Offset origin = Offset(
        (size.width - checkEdge) / 2,
        (size.height - checkEdge) / 2,
      );

      final Offset start = origin + Offset(
        checkEdge * _kCheckStart.dx,
        checkEdge * _kCheckStart.dy,
      );
      final Offset mid = origin + Offset(
        checkEdge * _kCheckMid.dx,
        checkEdge * _kCheckMid.dy,
      );
      final Offset end = origin + Offset(
        checkEdge * _kCheckEnd.dx,
        checkEdge * _kCheckEnd.dy,
      );

      final Path path = Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(mid.dx, mid.dy)
        ..lineTo(end.dx, end.dy);

      canvas.drawPath(path, checkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressCheckboxPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.shape != shape ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor ||
        oldDelegate.checkColor != checkColor ||
        oldDelegate.activeSide != activeSide ||
        oldDelegate.inactiveSide != inactiveSide;
  }
}
