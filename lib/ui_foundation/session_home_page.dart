import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/session.dart';
import 'package:social_learning/state/available_session_state.dart';
import 'package:social_learning/state/organizer_session_state.dart';
import 'package:social_learning/state/student_session_state.dart';
import 'package:social_learning/ui_foundation/bottom_bar.dart';
import 'package:social_learning/ui_foundation/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/navigation_enum.dart';
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
    // TODO: Check if the current user is the organizer of the session.

    String? sessionId = session.id;
    if (sessionId != null) {
      Navigator.pushNamed(context, NavigationEnum.sessionStudent.route,
          arguments: SessionStudentArgument(sessionId));
    }
  }

  @override
  void initState() {
    super.initState();

    _checkForActiveSession(context);
  }

  // Checks if there is an active session and re-directs accordingly.
  void _checkForActiveSession(BuildContext context) {
    OrganizerSessionState organizerSessionState =
        Provider.of<OrganizerSessionState>(context, listen: false);

    if (organizerSessionState.currentSession != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamed(context, NavigationEnum.sessionHost.route);
      });
      return;
    }

    StudentSessionState studentSessionState =
        Provider.of<StudentSessionState>(context, listen: false);

    if (studentSessionState.currentSession != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamed(context, NavigationEnum.sessionStudent.route,
            arguments: SessionStudentArgument(
                studentSessionState.currentSession!.id!));
      });
      return;
    }
  }
}
