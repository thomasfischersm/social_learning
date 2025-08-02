import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/organizer_session_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

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
        bottomNavigationBar: BottomBarV2.build(context),
        body: Align(
            alignment: Alignment.topCenter,
            child: CustomUiConstants.framePage(
                enableCourseLoadingGuard: true,
                Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomUiConstants.getTextPadding(
                Text('Create Session', style: CustomTextStyles.headline)),
              Consumer2<LibraryState, ApplicationState>(
                builder: (context, libraryState, applicationState, child) {
                  return Table(columnWidths: const <int, TableColumnWidth>{
                    0: IntrinsicColumnWidth(),
                    1: FlexColumnWidth(),
                  }, children: <TableRow>[
                    TableRow(children: <Widget>[
                      CustomUiConstants.getTextPadding(
                          const Text('Session name:')),
                      TextField(controller: sessionNameController),
                    ]),
                    TableRow(children: <Widget>[
                      CustomUiConstants.getTextPadding(
                          const Text('Organizer:')),
                      CustomUiConstants.getTextPadding(Text(
                          '${applicationState.currentUser?.displayName} (you)')),
                    ]),
                    TableRow(children: <Widget>[
                      CustomUiConstants.getTextPadding(const Text('Course')),
                      CustomUiConstants.getTextPadding(
                          Text('${libraryState.selectedCourse?.title}')),
                    ]),
                    ]);
                  // return GridView.count(
                  //   crossAxisCount: 2, shrinkWrap: true,
                  //   children: [
                  //     const Text('Session name:'),
                  //     TextField(
                  //       controller: sessionNameController,
                  //     ),
                  //     const Text('Organizer:'),
                  //     Text(
                  //         '${applicationState.currentUser?.displayName} (you)'),
                  //     const Text('Course'),
                  //     Text('${libraryState.selectedCourse?.title}'),
                  //   ],
                  // );
                },
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: () => Navigator.pushNamed(
                        context, NavigationEnum.sessionHome.route),
                    child: const Text('Cancel')),
                ElevatedButton(
                    onPressed: () {
                      _createSession(context, sessionNameController.text);
                    },
                    child: const Text('Continue')),
              ],
            )
          ],
        ))));
  }

  void _createSession(BuildContext context, String sessionName) {
    print('Attempting to create session $sessionName');

    var applicationState =
        Provider.of<ApplicationState>(context, listen: false);
    var libraryState = Provider.of<LibraryState>(context, listen: false);
    var organizerSessionState =
        Provider.of<OrganizerSessionState>(context, listen: false);

    organizerSessionState.createSession(
        sessionName, applicationState, libraryState);

    Navigator.pushNamed(context, NavigationEnum.sessionHost.route);
  }
}
