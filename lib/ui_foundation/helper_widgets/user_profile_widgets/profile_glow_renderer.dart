import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'profile_glow_painter.dart';

/// Renders a profile avatar with a progress belt and a rising-sun style glow.
///
/// This class focuses purely on drawing. It accepts the pieces required for
/// rendering and produces a [ui.Image] that callers can cache or paint into the
/// widget tree.
class ProfileGlowRenderer {
  final ui.Image avatar;
  final double avatarDiameter;
  final double beltWidth;
  final Color beltColor;
  final double teachLearnRatio;

  const ProfileGlowRenderer({
    required this.avatar,
    required this.avatarDiameter,
    required this.beltWidth,
    required this.beltColor,
    this.teachLearnRatio = 0.0,
  });

  /// Draws the avatar, belt, and glow to an off-screen canvas and returns the
  /// resulting image.
  Future<ui.Image> render() async {
    final double radius = avatarDiameter / 2;
    final double padding = 24; // space for glow
    final double canvasSize = avatarDiameter + padding * 2;
    final Offset center = Offset(canvasSize / 2, canvasSize / 2);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, canvasSize, canvasSize));

    final double ratio = ((teachLearnRatio - 0.5) / 0.5).clamp(0.0, 1.0);
    if (ratio > 0) {
      await ProfileGlowPainter.ensureShader();
      ProfileGlowPainter(
        avatarRadius: radius,
        glowStrength: ratio,
      ).paint(canvas, Size(canvasSize, canvasSize));
    }

    // Draw avatar
    final avatarRect = Rect.fromCircle(center: center, radius: radius);
    final srcRect =
        Rect.fromLTWH(0, 0, avatar.width.toDouble(), avatar.height.toDouble());
    canvas.save();
    canvas.clipPath(Path()..addOval(avatarRect));
    canvas.drawImageRect(avatar, srcRect, avatarRect, Paint());
    canvas.restore();

    // Draw belt ring
    final beltPaint = Paint()
      ..color = beltColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = beltWidth;
    canvas.drawCircle(center, radius + beltWidth / 2, beltPaint);

    final picture = recorder.endRecording();
    return picture.toImage(canvasSize.ceil(), canvasSize.ceil());
  }

}

