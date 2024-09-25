import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/session_pairing.dart';
import 'package:social_learning/data/session_participant.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/session_pairing/paired_session.dart';
import 'package:social_learning/session_pairing/session_pairing_algorithm.dart';
import 'package:social_learning/session_pairing/testing/session_pairing_algorithm_test.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/organizer_session_state.dart';
import 'package:social_learning/ui_foundation/bottom_bar.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants//custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/helper_widgets/dialog_utils.dart';
import 'package:social_learning/ui_foundation/lesson_detail_page.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

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
        bottomNavigationBar: BottomBarV2.build(context),
        body: Center(child: CustomUiConstants.framePage(
            Consumer<OrganizerSessionState>(
                builder: (context, organizerSessionState, child) {
          return Consumer<LibraryState>(
              builder: (context, libraryState, child) {
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
                Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                        onPressed: () =>
                            _pairNextRound(context, organizerSessionState),
                        child: const Text('Pair the next round'))),
                Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                        onPressed: () => DialogUtils.showConfirmationDialog(
                            context,
                            'End Session',
                            'Are you sure you want to end the session?',
                            () => _endSession(context, organizerSessionState)),
                        child: const Text('End the session'))),
                Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                        onPressed: () =>
                            SessionPairingAlgorithmTest().testAll(),
                        child: const Text('Test'))),
                _createPairingTable(organizerSessionState, libraryState),
              ],
            );
          });
        }))));
  }

  _createParticipantTable(OrganizerSessionState organizerSessionState) {
    List<TableRow> tableRows = <TableRow>[];

    for (SessionParticipant sessionParticipant
        in organizerSessionState.sessionParticipants) {
      User? participantUser = organizerSessionState.getUser(sessionParticipant);

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

  Table _createPairingTable(
      OrganizerSessionState organizerSessionState, LibraryState libraryState) {
    List<TableRow> tableRows = <TableRow>[];

    var roundNumberToSessionPairing =
        organizerSessionState.roundNumberToSessionPairing;
    List<int> sortedRounds = roundNumberToSessionPairing.keys.toList()..sort();
    sortedRounds = sortedRounds.reversed.toList();

    for (int round in sortedRounds) {
      tableRows.add(TableRow(children: <Widget>[
        // TODO: Set dark background color and span the whole row.
        Container(
            color: CustomUiConstants.accentedBackgroundColor,
            child:
                CustomUiConstants.getTextPadding(Text('Session ${round + 1}'))),
        Container(
            color: CustomUiConstants.accentedBackgroundColor,
            child: CustomUiConstants.getTextPadding(const Text(''))),
        Container(
            color: CustomUiConstants.accentedBackgroundColor,
            child: CustomUiConstants.getTextPadding(const Text(''))),
      ]));
      tableRows.add(TableRow(children: <Widget>[
        CustomUiConstants.getTextPadding(const Text("Mentor")),
        CustomUiConstants.getTextPadding(const Text('Mentee')),
        CustomUiConstants.getTextPadding(const Text('Lesson')),
      ]));

      List<SessionPairing> sessionPairings =
          roundNumberToSessionPairing[round]!;
      for (SessionPairing sessionPairing in sessionPairings) {
        print('mentorId = ${sessionPairing.mentorId.id}');
        User? mentor =
            organizerSessionState.getUserById(sessionPairing.mentorId.id);
        User? mentee =
            organizerSessionState.getUserById(sessionPairing.menteeId.id);
        Lesson? lesson = libraryState.findLesson(sessionPairing.lessonId.id);

        tableRows.add(TableRow(children: <Widget>[
          CustomUiConstants.getTextPadding(
              Text(mentor?.displayName ?? 'Error!!!')),
          CustomUiConstants.getTextPadding(
              Text(mentee?.displayName ?? 'Error!!!')),
          InkWell(
            onTap: () => _goToLesson(lesson),
            child: CustomUiConstants.getTextPadding(
                Text(lesson?.title ?? 'Error!!!')),
          ),
          // TODO: Create link.
        ]));
      }
    }

    return Table(columnWidths: const {
      0: FlexColumnWidth(),
      1: FlexColumnWidth(),
      2: FlexColumnWidth()
    }, children: tableRows);
  }

  _pairNextRound(
      BuildContext context, OrganizerSessionState organizerSessionState) {
    // Match students.
    var libraryState = Provider.of<LibraryState>(context, listen: false);
    PairedSession pairedSession = SessionPairingAlgorithm()
        .generateNextSessionPairing(organizerSessionState, libraryState);

    // Save next round to the Firestore.
    organizerSessionState.saveNextRound(pairedSession);
  }

  _endSession(
      BuildContext context, OrganizerSessionState organizerSessionState) {
    organizerSessionState.endSession();

    Navigator.pushNamed(context, NavigationEnum.levelList.route);
  }

  _goToLesson(Lesson? lesson) {
    String? lessonId = lesson?.id;
    if (lessonId != null) {
      Navigator.pushNamed(context, NavigationEnum.lessonDetail.route,
          arguments: LessonDetailArgument(lessonId));
    }
  }
}
