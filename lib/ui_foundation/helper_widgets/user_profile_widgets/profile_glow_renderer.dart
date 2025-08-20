import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Renders a profile avatar with a belt ring and an optional rising-sun glow.
///
/// This class focuses solely on drawing. It accepts the pieces required for
/// rendering and produces a [ui.Image] that callers can cache or paint into the
/// widget tree. The glow is generated with radial gradients using color stops
/// computed in the Oklab colour space to achieve a quick-to-slow fade similar
/// to a `1/x` curve.
class ProfileGlowRenderer {
  final ui.Image avatar;
  final double avatarDiameter;
  final double beltWidth;
  final Color beltColor;

  /// Draw glow only when the ratio exceeds 0.5.
  final double teachLearnRatio;

  /// Radius factor for the large glow circle relative to the avatar radius.
  final double innerGlowFactor;

  /// How far the large glow circle extends beyond the avatar radius.
  final double glowExtensionFactor;

  /// Radius factor for the bright sun dot.
  final double sunDotFactor;

  const ProfileGlowRenderer({
    required this.avatar,
    required this.avatarDiameter,
    required this.beltWidth,
    required this.beltColor,
    this.teachLearnRatio = 0.0,
    this.innerGlowFactor = 0.9,
    this.glowExtensionFactor = 0.1,
    this.sunDotFactor = 0.05,
  });

  /// Draws the avatar, belt, and glow to an off-screen canvas and returns the
  /// resulting image.
  Future<ui.Image> render() async {
    final double avatarRadius = avatarDiameter / 2;
    // Extra space so the glow and sun dot are not clipped.
    final double padding =
        avatarDiameter * glowExtensionFactor + avatarRadius * sunDotFactor;
    final double canvasSize = avatarDiameter + padding * 2;
    final Offset center = Offset(canvasSize / 2, canvasSize / 2);

    final recorder = ui.PictureRecorder();
    final canvas =
        Canvas(recorder, Rect.fromLTWH(0, 0, canvasSize, canvasSize));

    if (teachLearnRatio >= 0.5) {
      _drawGlow(canvas, center, avatarRadius);
    }

    // Draw avatar image.
    final avatarRect = Rect.fromCircle(center: center, radius: avatarRadius);
    final srcRect =
        Rect.fromLTWH(0, 0, avatar.width.toDouble(), avatar.height.toDouble());
    canvas.save();
    canvas.clipPath(Path()..addOval(avatarRect));
    canvas.drawImageRect(avatar, srcRect, avatarRect, Paint());
    canvas.restore();

    // Draw belt ring.
    final beltPaint = Paint()
      ..color = beltColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = beltWidth;
    canvas.drawCircle(center, avatarRadius + beltWidth / 2, beltPaint);

    final picture = recorder.endRecording();
    return picture.toImage(canvasSize.ceil(), canvasSize.ceil());
  }

  void _drawGlow(Canvas canvas, Offset center, double avatarRadius) {
    final double offset = avatarDiameter * glowExtensionFactor;
    final double glowRadius = avatarRadius * innerGlowFactor + offset;
    final Offset glowCenter = center.translate(-offset, offset);

    final _GradientStops stops = _buildOklabGradient(
      const [
        Color(0xFFFFFFFF), // white
        Color(0xFFFFF59D), // soft yellow
        Color(0xFFFFB74D), // orange
        Color(0x00FFFFFF), // transparent
      ],
      const [0.0, 0.4, 0.7, 1.0],
      8,
    );

    final Paint glowPaint = Paint()
      ..shader = ui.Gradient.radial(
        glowCenter,
        glowRadius,
        stops.colors,
        stops.stops,
        TileMode.clamp,
      );
    canvas.drawCircle(glowCenter, glowRadius, glowPaint);

    final double sunRadius = avatarRadius * sunDotFactor;
    final double sqrt2 = math.sqrt2;
    final Offset sunCenter =
        center + Offset(avatarRadius / sqrt2, -avatarRadius / sqrt2);
    final Paint sunPaint = Paint()
      ..shader = ui.Gradient.radial(
        sunCenter,
        sunRadius,
        stops.colors,
        stops.stops,
        TileMode.clamp,
      );
    canvas.drawCircle(sunCenter, sunRadius, sunPaint);
  }
}

class _GradientStops {
  final List<Color> colors;
  final List<double> stops;
  const _GradientStops(this.colors, this.stops);
}

_GradientStops _buildOklabGradient(
    List<Color> keyColors, List<double> keyStops, int stepsPerSegment) {
  final colors = <Color>[];
  final stops = <double>[];

  for (int i = 0; i < keyColors.length - 1; i++) {
    for (int j = 0; j < stepsPerSegment; j++) {
      final t = j / stepsPerSegment;
      final globalT =
          keyStops[i] + (keyStops[i + 1] - keyStops[i]) * t;
      colors.add(_oklabLerp(keyColors[i], keyColors[i + 1], t));
      stops.add(globalT);
    }
  }

  colors.add(keyColors.last);
  stops.add(keyStops.last);

  return _GradientStops(colors, stops);
}

Color _oklabLerp(Color a, Color b, double t) {
  final _Oklab labA = _toOklab(a);
  final _Oklab labB = _toOklab(b);
  final _Oklab lab = _Oklab(
    labA.l + (labB.l - labA.l) * t,
    labA.a + (labB.a - labA.a) * t,
    labA.b + (labB.b - labA.b) * t,
  );
  final Color rgb = _fromOklab(lab);
  final double alpha = a.opacity + (b.opacity - a.opacity) * t;
  return rgb.withOpacity(alpha);
}

class _Oklab {
  final double l;
  final double a;
  final double b;
  const _Oklab(this.l, this.a, this.b);
}

double _srgbToLinear(double c) {
  if (c <= 0.04045) return c / 12.92;
  return math.pow((c + 0.055) / 1.055, 2.4).toDouble();
}

double _linearToSrgb(double c) {
  if (c <= 0.0031308) return 12.92 * c;
  return 1.055 * math.pow(c, 1 / 2.4) - 0.055;
}

_Oklab _toOklab(Color color) {
  final r = _srgbToLinear(color.red / 255.0);
  final g = _srgbToLinear(color.green / 255.0);
  final b = _srgbToLinear(color.blue / 255.0);

  final l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b;
  final m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b;
  final s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b;

  final l_ = math.pow(l, 1 / 3).toDouble();
  final m_ = math.pow(m, 1 / 3).toDouble();
  final s_ = math.pow(s, 1 / 3).toDouble();

  return _Oklab(
    0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_,
    1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_,
    0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_,
  );
}

Color _fromOklab(_Oklab lab) {
  final l_ = lab.l + 0.3963377774 * lab.a + 0.2158037573 * lab.b;
  final m_ = lab.l - 0.1055613458 * lab.a - 0.0638541728 * lab.b;
  final s_ = lab.l - 0.0894841775 * lab.a - 1.2914855480 * lab.b;

  final l = l_ * l_ * l_;
  final m = m_ * m_ * m_;
  final s = s_ * s_ * s_;

  double r = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s;
  double g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s;
  double b = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s;

  r = _linearToSrgb(r);
  g = _linearToSrgb(g);
  b = _linearToSrgb(b);

  return Color.fromARGB(
    255,
    (r.clamp(0.0, 1.0) * 255).round(),
    (g.clamp(0.0, 1.0) * 255).round(),
    (b.clamp(0.0, 1.0) * 255).round(),
  );
}

