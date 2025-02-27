import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/session.dart';
import 'package:social_learning/state/available_session_state.dart';
import 'package:social_learning/ui_foundation/bottom_bar.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';
import 'package:social_learning/ui_foundation/session_student_page.dart';

class SessionHomePage extends StatefulWidget {
  const SessionHomePage({super.key});

  @override
  _SessionHomePageState createState() => _SessionHomePageState();
}

class _SessionHomePageState extends State<SessionHomePage> {
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomUiConstants.getTextPadding(
                Text('Join a session', style: CustomTextStyles.headline),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Consumer<AvailableSessionState>(
                  builder: (context, availableSessionState, child) =>
                      _buildAvailableSessions(context, availableSessionState),
                ),
              ),
              CustomUiConstants.getDivider(),
              Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      NavigationEnum.sessionCreateWarning.route,
                    ),
                    child: const Text('Create a new session'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a list of available sessions.
  Widget _buildAvailableSessions(
      BuildContext context, AvailableSessionState state) {
    if (state.availableSessions.isEmpty) {
      return Text(
        'No sessions available.',
        style: CustomTextStyles.getBody(context),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: state.availableSessions.map((Session session) {
        final sessionLabel =
            '${session.name} by ${session.organizerName} with ${session.participantCount} participants';
        return InkWell(
          onTap: () => _joinSession(session),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              sessionLabel,
              style: CustomTextStyles.getBody(context),
            ),
          ),
        );
      }).toList(),
    );
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
