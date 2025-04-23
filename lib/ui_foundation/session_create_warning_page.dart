import 'package:flutter/material.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

class SessionCreateWarningPage extends StatefulWidget {
  const SessionCreateWarningPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return SessionCreateWarningState();
  }
}

class SessionCreateWarningState extends State<SessionCreateWarningPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Learning Lab'),
        ),
        bottomNavigationBar: BottomBarV2.build(context),
        body: Align(
            alignment: Alignment.topCenter,
            child: CustomUiConstants.framePage(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomUiConstants.getTextPadding(
                Text('Hold up!', style: CustomTextStyles.headline)),
            CustomUiConstants.getTextPadding(Text(
                'You are probably a regular student and are looking to join the session for the learning lab that you are in. Cancel and join the existing session.',
                style: CustomTextStyles.getBody(context))),
            CustomUiConstants.getTextPadding(Text(
                'Creating a session is for when you are with your friends and want to run your own learning lab.',
                style: CustomTextStyles.getBody(context))),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: () => Navigator.pushNamed(
                        context, NavigationEnum.sessionHome.route),
                    child: const Text('Cancel')),
                ElevatedButton(
                    onPressed: () => Navigator.pushNamed(
                        context,
                        NavigationEnum
                            .sessionCreate.route),
                    child: const Text('Continue')),
              ],
            )
          ],
        ))));
  }
}
