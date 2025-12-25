import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/session_pairing.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/student_session_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/general/learning_lab_app_bar.dart';
import 'package:social_learning/ui_foundation/helper_widgets/session_round_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/dialog_utils.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';

class SessionStudentArgument {
  String sessionId;

  SessionStudentArgument(this.sessionId);
}

class SessionStudentPage extends StatefulWidget {
  const SessionStudentPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return SessionStudentState();
  }
}

class SessionStudentState extends State<SessionStudentPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SessionStudentArgument? argument =
          ModalRoute.of(context)!.settings.arguments as SessionStudentArgument?;
      if (argument != null) {
        String sessionId = argument.sessionId;
        var studentSessionState =
            Provider.of<StudentSessionState>(context, listen: false);
        studentSessionState.attemptToJoin(sessionId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const LearningLabAppBar(),
      bottomNavigationBar: BottomBarV2.build(context),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          DialogUtils.showConfirmationDialog(
            context,
            'Leave Session',
            'Are you sure you want to leave the session?',
            () {
              Provider.of<StudentSessionState>(context, listen: false)
                  .leaveSession()
                  .then((_) {
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/session_home');
                }
              });
            },
          );
        },
        child: const Icon(Icons.exit_to_app, color: Colors.grey),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: CustomUiConstants.framePage(
          Consumer3<ApplicationState, LibraryState, StudentSessionState>(
            builder: (context, applicationState, libraryState,
                studentSessionState, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (studentSessionState.currentSession?.isActive == false ||
                      studentSessionState.currentSession == null)
                    CustomUiConstants.getTextPadding(
                      Text('The session has ended!',
                          style: CustomTextStyles.subHeadline),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Session: ${studentSessionState.currentSession?.name ?? ''}',
                        style: CustomTextStyles.headline,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  _createPairingTable2(
                      studentSessionState, libraryState, applicationState),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _createPairingTable2(StudentSessionState studentSessionState,
      LibraryState libraryState, ApplicationState applicationState) {
    List<Widget> children = <Widget>[];

    String? currentUserId = applicationState.currentUser?.id;

    var roundNumberToSessionPairing =
        studentSessionState.roundNumberToSessionPairing;
    if (roundNumberToSessionPairing.isEmpty) {
      return Column(children: [
        CustomUiConstants.getTextPadding(Text(
          'Waiting for the instructor to create the first pairing.',
          style: CustomTextStyles.getBody(context),
          textAlign: TextAlign.center,
        )),
      ]);
    }
    List<int> sortedRounds = roundNumberToSessionPairing.keys.toList()..sort();
    sortedRounds = sortedRounds.reversed.toList();

    for (int round in sortedRounds) {
      bool hasAtLeastOnePairing = false;

      List<SessionPairing> sessionPairings =
          roundNumberToSessionPairing[round]!;
      for (SessionPairing sessionPairing in sessionPairings) {
        if ((sessionPairing.mentorId?.id != currentUserId) &&
            (sessionPairing.menteeId?.id != currentUserId)) {
          // Only show pairings if they involve the current student.
          continue;
        }

        children.add(SessionRoundCard('${round + 1}', sessionPairing,
            studentSessionState, libraryState, applicationState));
        hasAtLeastOnePairing = true;
      }

      if (!hasAtLeastOnePairing) {
        children.add(SessionRoundCard('${round + 1}', null, studentSessionState,
            libraryState, applicationState));
      }
    }

    return Column(children: children);
  }
}
