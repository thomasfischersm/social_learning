import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:social_learning/ui_foundation/helper_widgets/general/background_image_style.dart';

typedef CardBuilder = Widget Function(BuildContext context, Widget content);

class BackgroundImageCard extends StatelessWidget {
  final ImageProvider? image;
  final Widget child;

  final BoxFit fit;
  final Alignment alignment;
  final BackgroundImageStyle style;

  /// Optional customization; defaults to a normal `Card`.
  final CardBuilder? cardBuilder;

  const BackgroundImageCard({
    super.key,
    required this.child,
    this.image,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.style = const BackgroundImageStyle(),
    this.cardBuilder,
  });

  static Widget defaultCardBuilder(BuildContext context, Widget content) {
    return Card(
      clipBehavior: Clip.antiAlias, // important: clip background to shape
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    final builder = cardBuilder ?? BackgroundImageCard.defaultCardBuilder;

    final content = Stack(
      children: [
        if (image != null)
          Positioned.fill(
            child: _StyledBackground(
              image: image!,
              fit: fit,
              alignment: alignment,
              style: style,
            ),
          ),

        // Foreground
        Positioned.fill(child: child),
      ],
    );

    return builder(context, content);
  }
}

class _StyledBackground extends StatelessWidget {
  final ImageProvider image;
  final BoxFit fit;
  final Alignment alignment;
  final BackgroundImageStyle style;

  const _StyledBackground({
    required this.image,
    required this.fit,
    required this.alignment,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    Widget base = Image(image: image, fit: fit, alignment: alignment);

    // Partial desaturation by overlaying a grayscale version
    if (style.desaturate > 0) {
      final gray = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: base,
      );

      base = Stack(
        children: [
          Positioned.fill(
              child: Image(image: image, fit: fit, alignment: alignment)),
          Positioned.fill(
              child:
                  Opacity(opacity: style.desaturate.clamp(0, 1), child: gray)),
        ],
      );
    }

    return Stack(
      children: [
        Positioned.fill(child: base),

        // Blur the already-drawn background image
        if (style.blurSigma > 0)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                  sigmaX: style.blurSigma, sigmaY: style.blurSigma),
              child: const SizedBox(),
            ),
          ),

        // Wash (main readability lever)
        Positioned.fill(
          child: Container(
            color: style.washColor.withAlpha(
              (style.washOpacity.clamp(0.0, 1.0) * 255).round(),
            ),
          ),
        ),

        // Optional gradient for legibility
        if (style.gradientOverlay != null)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: style.gradientOverlay),
            ),
          ),
      ],
    );
  }
}
