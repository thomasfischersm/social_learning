import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/session.dart';
import 'package:social_learning/state/available_session_state.dart';
import 'package:social_learning/ui_foundation/bottom_bar.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';
import 'package:social_learning/ui_foundation/session_student_page.dart';

class SessionHomePage extends StatefulWidget {
  const SessionHomePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return SessionHomeState();
  }
}

class SessionHomeState extends State<SessionHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Learning Lab'),
        ),
        bottomNavigationBar: const BottomBar(),
        body: Center(
            child: CustomUiConstants.framePage(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomUiConstants.getTextPadding(
                Text('Join a session', style: CustomTextStyles.headline)),
            Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Consumer<AvailableSessionState>(
                    builder: (context, availableSessionState, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:
                        _showAvailableSessions(context, availableSessionState),
                  );
                })),
            CustomUiConstants.getDivider(),
            Row(
              children: [
                const Spacer(),
                TextButton(
                    onPressed: () => Navigator.pushNamed(
                        context, NavigationEnum.sessionCreateWarning.route),
                    child: const Text('Create a new session'))
              ],
            ),
          ],
        ))));
  }

  List<Widget> _showAvailableSessions(
      BuildContext context, AvailableSessionState availableSessionState) {
    List<Widget> result = [];
    if (availableSessionState.availableSessions.isEmpty) {
      result.add(Text('No sessions available.',
          style: CustomTextStyles.getBody(context)));
    } else {
      for (Session session in availableSessionState.availableSessions) {
        var sessionLabel =
            '${session.name} by ${session.organizerName} with ${session.participantCount} participants';
        result.add(InkWell(
            onTap: () {
              _joinSession(session, context);
            },
            child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(sessionLabel,
                    style: CustomTextStyles.getBody(context)))));
      }
    }

    return result;
  }

  _navigateToCreateSession() {
    Navigator.pushNamed(context, NavigationEnum.cmsLesson.route);
  }

  _joinSession(Session session, BuildContext context) {
    print('Tapped to join a session');

    String? sessionId = session.id;
    if (sessionId != null) {
      Navigator.pushNamed(context, NavigationEnum.sessionStudent.route,
          arguments: SessionStudentArgument(sessionId));
    }
  }
}
