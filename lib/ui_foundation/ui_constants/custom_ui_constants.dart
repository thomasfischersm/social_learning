import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:social_learning/ui_foundation/helper_widgets/general/auth_guard.dart';
import 'package:social_learning/ui_foundation/helper_widgets/general/course_analytics_guard.dart';
import 'package:social_learning/ui_foundation/helper_widgets/general/creator_guard.dart';
import 'package:social_learning/ui_foundation/helper_widgets/general/course_loading_guard.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomUiConstants {
  static Color accentedBackgroundColor = Colors.black12;

  static EdgeInsets getScreenPadding(BuildContext context) =>
      EdgeInsets.all(MediaQuery.of(context).size.width * .06);

  static Divider getDivider() => const Divider(
        color: Color.fromRGBO(153, 153, 153, 1),
        thickness: 1.5,
      );

  static Padding getTextPadding(Text text) =>
      Padding(padding: const EdgeInsets.only(bottom: 8), child: text);

  static Padding getRichTextPadding(RichText text) =>
      Padding(padding: const EdgeInsets.only(bottom: 8), child: text);

  static Padding getIndentationTextPadding(Widget widget) =>
      Padding(padding: const EdgeInsets.only(left: 8), child: widget);

  /// Standard padding used for text field content.
  static const EdgeInsets standardInputPadding =
      EdgeInsets.symmetric(horizontal: 12, vertical: 10);

  static const double profileBorderWidth = 2.0;

  /// Returns an [OutlineInputBorder] with consistent radius and color.
  static OutlineInputBorder getInputBorder(
      {Color color = const Color(0xFFBDBDBD), double width = 1, double radius = 8}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  /// Builds a filled [InputDecoration] using the application's standard style.
  static InputDecoration getFilledInputDecoration(
    BuildContext context, {
    String? labelText,
    String? hintText,
    Color enabledColor = const Color(0xFFBDBDBD),
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: standardInputPadding,
      enabledBorder: getInputBorder(color: enabledColor),
      focusedBorder:
          getInputBorder(color: Theme.of(context).colorScheme.primary, width: 2),
    );
  }

  static Widget getGeneralFooter(BuildContext context,
      {bool withDivider = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (withDivider)
          Padding(padding: const EdgeInsets.only(top: 8), child: getDivider()),
        RichText(
            text: TextSpan(children: [
          TextSpan(text: 'Contact: ', style: CustomTextStyles.getBody(context)),
          TextSpan(
              text: 'thomas@learninglab.fans',
              style: CustomTextStyles.getLink(context),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  launchUrl(Uri.parse('mailto:thomas@learninglab.fans'));
                }),
        ])),
        const Text('(C) 2024 Thomas Fischer'),
      ],
    );
  }

  static Widget framePage(Widget child,
      {bool enableScrolling = true,
      bool enableAuthGuard = true,
      bool enableCreatorGuard = false,
      bool enableCourseLoadingGuard = false,
      bool enableCourseAnalyticsGuard = false}) {

    var creatorGuardEnabled = enableCreatorGuard;
    var courseLoadingGuardEnabled = enableCourseLoadingGuard;

    if (enableCourseAnalyticsGuard) {
      creatorGuardEnabled = true;
      courseLoadingGuardEnabled = true;
    }

    // Add guards in reverse order. The guard added last will be executed first.
    // This is important because when the user isn't logged in, exceptions
    // could be thrown if the user isn't redirected to sign-in right away.
    if (courseLoadingGuardEnabled) {
      child = CourseLoadingGuard(child: child);
    }

    if (creatorGuardEnabled) {
      child = CreatorGuard(child: child);
    }

    if (enableAuthGuard) {
      child = AuthGuard(child: child);
    }

    if (enableCourseAnalyticsGuard) {
      child = CourseAnalyticsGuard(child: child);
    }

    if (enableScrolling) {
      child = SingleChildScrollView(child: child);
    }

    return Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 730),
        padding: const EdgeInsets.all(5.0 * 3.1),
        child: SafeArea(child: child));
  }
}
