import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/student_session_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/dialog_utils.dart';
import 'package:social_learning/ui_foundation/helper_widgets/general/learning_lab_app_bar.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';

class AdvancedPairingStudentArgument {
  String sessionId;

  AdvancedPairingStudentArgument(this.sessionId);
}

class AdvancedPairingStudentPage extends StatefulWidget {
  const AdvancedPairingStudentPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _AdvancedPairingStudentState();
  }
}

class _AdvancedPairingStudentState extends State<AdvancedPairingStudentPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdvancedPairingStudentArgument? argument =
          ModalRoute.of(context)!.settings.arguments
              as AdvancedPairingStudentArgument?;
      if (argument != null) {
        String sessionId = argument.sessionId;
        StudentSessionState studentSessionState =
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
              // TODO: Add advanced pairing student page content.
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}
