import 'package:flutter/material.dart';

@immutable
class BackgroundImageStyle {
  final double blurSigma;      // 0 = none
  final double washOpacity;    // 0..1
  final Color washColor;       // usually white or tint
  final double desaturate;     // 0..1 (0 = none, 1 = full grayscale)
  final Gradient? gradientOverlay;

  const BackgroundImageStyle({
    this.blurSigma = 2.0,
    this.washOpacity = 0.65,
    this.washColor = Colors.white,
    this.desaturate = 0.25,
    this.gradientOverlay,
  });
}