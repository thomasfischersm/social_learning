import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/session.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/available_session_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/organizer_session_state.dart';
import 'package:social_learning/ui_foundation/bottom_bar.dart';
import 'package:social_learning/ui_foundation/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/navigation_enum.dart';

class SessionCreatePage extends StatefulWidget {
  const SessionCreatePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return SessionCreateState();
  }
}

class SessionCreateState extends State<SessionCreatePage> {
  final sessionNameController = TextEditingController();

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
                Text('Create Session', style: CustomTextStyles.headline)),
            Consumer<LibraryState>(
              builder: (context, libraryState, child) {
                return Consumer<ApplicationState>(
                    builder: (context, applicationState, child) {
                  return GridView.count(
                    crossAxisCount: 2, shrinkWrap: true,
                    children: [
                      const Text('Session name:'),
                      TextField(
                        controller: sessionNameController,
                      ),
                      const Text('Organizer:'),
                      Text(
                          '${applicationState.currentUser?.displayName} (you)'),
                      const Text('Course'),
                      Text('${libraryState.selectedCourse?.title}'),
                    ],
                  );
                });
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: () {
                      _createSession(context, sessionNameController.text);
                    },
                    child: const Text('Continue')),
                TextButton(
                    onPressed: () => Navigator.pushNamed(
                        context, NavigationEnum.sessionHome.route),
                    child: const Text('Cancel'))
              ],
            )
          ],
        ))));
  }

  void _createSession(BuildContext context, String sessionName) {
    print('Attempting to create session $sessionName');

    var applicationState = Provider.of<ApplicationState>(context, listen: false);
    var libraryState = Provider.of<LibraryState>(context, listen: false);
    var organizerSessionState = Provider.of<OrganizerSessionState>(context, listen: false);

    organizerSessionState.createSession(sessionName, applicationState, libraryState);

    // TODO: Re-direct to the session page.
  }
}
