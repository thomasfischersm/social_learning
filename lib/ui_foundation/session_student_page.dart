import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/state/student_session_state.dart';
import 'package:social_learning/ui_foundation/bottom_bar.dart';
import 'package:social_learning/ui_foundation/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/custom_ui_constants.dart';

class SessionStudentArgument {
  String sessionId;

  SessionStudentArgument(this.sessionId);
}

class SessionStudentPage extends StatefulWidget {
  const SessionStudentPage({super.key});

  State<StatefulWidget> createState() {
    return SessionStudentState();
  }
}

class SessionStudentState extends State<SessionStudentPage> {
  @override
  Widget build(BuildContext context) {
    SessionStudentArgument? argument =
        ModalRoute.of(context)!.settings.arguments as SessionStudentArgument?;
    if (argument != null) {
      String sessionId = argument.sessionId;
      var studentSessionState =
          Provider.of<StudentSessionState>(context, listen: false);
      studentSessionState.attemptToJoin(sessionId, context);
    }

    return Scaffold(
        appBar: AppBar(title: const Text('Learning Lab')),
        bottomNavigationBar: const BottomBar(),
        body: Center(child: CustomUiConstants.framePage(
            Consumer<StudentSessionState>(
                builder: (context, studentSessionState, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomUiConstants.getTextPadding(Text(
                  'Attending Session: ${studentSessionState.currentSession?.name}',
                  style: CustomTextStyles.headline)),
            ],
          );
        }))));
  }
}
