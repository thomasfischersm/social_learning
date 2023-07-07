import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:social_learning/ui_foundation/custom_text_styles.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomUiConstants {
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
        const Text('(C) 2023 Thomas Fischer'),
      ],
    );
  }
}
