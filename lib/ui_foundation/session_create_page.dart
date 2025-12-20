import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/organizer_session_state.dart';
import 'package:social_learning/data/session_type.dart';
import 'package:social_learning/ui_foundation/helper_widgets/dialog_utils.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/general/learning_lab_app_bar.dart';
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
  SessionType _sessionType = SessionType.automaticManual;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: const LearningLabAppBar(),
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
                  TableRow(children: <Widget>[
                    CustomUiConstants.getTextPadding(
                        const Text('Session type:')),
                    CustomUiConstants.getIndentationTextPadding(Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ..._buildSessionTypeOptions(context),
                      ],
                    )),
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
                      _createSession(
                          context, sessionNameController.text, _sessionType);
                    },
                    child: const Text('Continue')),
              ],
            )
          ],
        ))));
  }

  void _createSession(
      BuildContext context, String sessionName, SessionType sessionType) {
    print('Attempting to create session $sessionName');

    var applicationState =
        Provider.of<ApplicationState>(context, listen: false);
    var libraryState = Provider.of<LibraryState>(context, listen: false);
    var organizerSessionState =
        Provider.of<OrganizerSessionState>(context, listen: false);

    organizerSessionState
        .createSession(sessionName, applicationState, libraryState, sessionType);

    Navigator.pushNamed(context, NavigationEnum.sessionHost.route);
  }

  List<Widget> _buildSessionTypeOptions(BuildContext context) {
    const sessionTypeOptions = [
      _SessionTypeOption(
        SessionType.automaticManual,
        'Automatic pairing with manual override',
        'As an instructor, you start each session. A smart algorithm will pair students. You have the option to change partners and assigned lessons.\n\nNote: The smart algorithm considers many factors that would make for the best pairings. For example, it\'ll look into the future to detect any lesson that might become a bottleneck with not enough mentors.',
      ),
      _SessionTypeOption(
        SessionType.powerMode,
        'Power mode for advanced control',
        'The power mode allows you to extremely quickly pair students with minimal clicks. There is a learning curve to understanding this powerful user interface.',
      ),
      _SessionTypeOption(
        SessionType.partyMode,
        'Party mode for mingling',
        'This mode is optimal for social events where the focus is on mingling. Students can request to be paired. They will be paired with available students or soon-to-be-available students. This works great for where lessons take a variable amount of time and students may come in and out of wanting to learn.',
      ),
    ];

    return sessionTypeOptions
        .map((option) =>
            _buildSessionTypeOption(option.type, option.label, option.infoText, context))
        .toList();
  }

  Widget _buildSessionTypeOption(SessionType value, String label,
      String infoText, BuildContext context) {
    return Row(
      children: [
        Radio<SessionType>(
            value: value,
            groupValue: _sessionType,
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() {
                  _sessionType = newValue;
                });
              }
            }),
        Expanded(child: Text(label)),
        IconButton(
            onPressed: () {
              DialogUtils.showInfoDialog(context, label, infoText, () {});
            },
            icon: const Icon(Icons.info_outline, color: Colors.grey)),
      ],
    );
  }
}

class _SessionTypeOption {
  final SessionType type;
  final String label;
  final String infoText;

  const _SessionTypeOption(this.type, this.label, this.infoText);
}
