import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Paints a rising-sun style glow around a circular avatar using a custom
/// fragment shader. The shader renders a non-linear 1/x halo with a
/// white→yellow→orange color ramp, a dark contrast ring, and optional sun
/// flares whose intensity grows with [glowStrength].
class ProfileGlowPainter extends CustomPainter {
  final double avatarRadius;
  final double glowStrength; // 0.0 - 1.0

  static ui.FragmentProgram? _program;

  /// Loads the fragment program if it hasn't been loaded yet.
  static Future<void> ensureShader() async {
    _program ??=
        await ui.FragmentProgram.fromAsset('shaders/profile_glow.frag');
  }

  const ProfileGlowPainter({
    required this.avatarRadius,
    required this.glowStrength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (_program == null) return;
    final shader = _program!.fragmentShader()
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, avatarRadius)
      ..setFloat(3, glowStrength);

    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant ProfileGlowPainter oldDelegate) {
    return oldDelegate.avatarRadius != avatarRadius ||
        oldDelegate.glowStrength != glowStrength;
  }
}
