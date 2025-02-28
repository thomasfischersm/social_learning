import 'package:flutter/material.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/session_widgets/in_person_session_section.dart';
import 'package:social_learning/ui_foundation/helper_widgets/session_widgets/online_session_section.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';

class SessionHomePage extends StatefulWidget {
  const SessionHomePage({super.key});

  @override
  SessionHomePageState createState() => SessionHomePageState();
}

class SessionHomePageState extends State<SessionHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Learning Lab'),
        ),
        bottomNavigationBar: BottomBarV2.build(context),
        body: Align(
          alignment: Alignment.topCenter,
          child: CustomUiConstants.framePage(
            enableScrolling: false,
            Column(
              children: [
                // Top section: scrollable in-person sessions.
                Flexible(flex: 1, child: const InPersonSessionSection()),
                SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                // Bottom section: online session section (fixed at bottom).
                if (false)
                  Flexible(flex: 1, child: const OnlineSessionSection()),
              ],
            ),
          ),
        ));
  }
}
