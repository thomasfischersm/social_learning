import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/session_participant.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/organizer_session_state.dart';
import 'package:social_learning/ui_foundation/bottom_bar.dart';
import 'package:social_learning/ui_foundation/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/custom_ui_constants.dart';

class SessionHostPage extends StatefulWidget {
  const SessionHostPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return SessionHostState();
  }
}

class SessionHostState extends State<SessionHostPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Learning Lab')),
        bottomNavigationBar: const BottomBar(),
        body: Center(child: CustomUiConstants.framePage(
            Consumer<OrganizerSessionState>(
                builder: (context, organizerSessionState, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomUiConstants.getTextPadding(Text(
                  'Host Session: ${organizerSessionState.currentSession?.name}',
                  style: CustomTextStyles.headline)),
              CustomUiConstants.getTextPadding(Text(
                  '${organizerSessionState.currentSession?.participantCount} Participants',
                  style: CustomTextStyles.subHeadline)),
              _createParticipantTable(organizerSessionState),
            ],
          );
        }))));
  }

  _createParticipantTable(OrganizerSessionState organizerSessionState) {
    List<TableRow> tableRows = <TableRow>[];

    for (SessionParticipant sessionParticipant
        in organizerSessionState.sessionParticipants) {
      User? participantUser =
          organizerSessionState.getParticipantUser(sessionParticipant);

      tableRows.add(TableRow(children: <Widget>[
        CustomUiConstants.getTextPadding(
            Text(participantUser?.displayName ?? 'Error!!!')),
        CustomUiConstants.getTextPadding(
            Text(sessionParticipant.isInstructor ? 'Instructor' : 'Student')),
      ]));
    }

    return Table(
        columnWidths: const {0: FlexColumnWidth(), 1: IntrinsicColumnWidth()},
        children: tableRows);
  }
}
