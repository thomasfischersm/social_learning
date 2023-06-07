import 'package:flutter/material.dart';

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
}
