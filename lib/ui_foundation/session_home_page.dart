import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/general/learning_lab_app_bar.dart';
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
        appBar: const LearningLabAppBar(),
        bottomNavigationBar: BottomBarV2.build(context),
        body: Align(
          alignment: Alignment.topCenter,
          child: CustomUiConstants.framePage(
              enableScrolling: false,
              enableCourseLoadingGuard: true,
              Consumer<LibraryState>(builder: (context, libraryState, child) {
                return Column(
                  children: [
                    // Top section: scrollable in-person sessions.
                    Flexible(
                        flex: 1,
                        child: const Column(
                          children: [InPersonSessionSection(), Spacer()],
                        )),
                    SizedBox(
                        height: MediaQuery.of(context).size.height * 0.02),
                    // Bottom section: online session section (fixed at bottom).
                    Flexible(
                        flex: 1,
                        child: const Column(
                          children: [OnlineSessionSection()],
                        )),
                  ],
                );
              })),
        ));
  }
}
