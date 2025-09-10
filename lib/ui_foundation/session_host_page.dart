import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/session_pairing.dart';
import 'package:social_learning/data/session_participant.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/session_pairing/paired_session.dart';
import 'package:social_learning/session_pairing/session_pairing_algorithm.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/organizer_session_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/general/learning_lab_app_bar.dart';
import 'package:social_learning/ui_foundation/helper_widgets/lesson_table_cell.dart';
import 'package:social_learning/ui_foundation/helper_widgets/mentee_table_cell.dart';
import 'package:social_learning/ui_foundation/helper_widgets/mentor_table_cell.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants//custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/helper_widgets/dialog_utils.dart';
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
        appBar: const LearningLabAppBar(),
        floatingActionButton: SpeedDial(
            icon: Icons.more_vert,
            activeIcon: Icons.close,
            children: [
              SpeedDialChild(
                  onTap: () => _pairNextRound(context),
                  child: Icon(Icons.shuffle),
                  label: 'Pair the next round'),
              SpeedDialChild(
                  onTap: () => _endSession(context),
                  child: Icon(Icons.exit_to_app),
                  label: 'End the session')
            ]),
        bottomNavigationBar: BottomBarV2.build(context),
        body: Align(
            alignment: Alignment.topCenter,
            child: CustomUiConstants.framePage(
                enableCourseLoadingGuard: true,
                Consumer2<OrganizerSessionState, LibraryState>(builder:
                    (context, organizerSessionState, libraryState, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomUiConstants.getTextPadding(Text(
                      'Host Session: ${organizerSessionState.currentSession?.name}',
                      style: CustomTextStyles.headline)),
                  CustomUiConstants.getTextPadding(Text(
                      '${organizerSessionState.currentSession?.participantCount} Participants',
                      style: CustomTextStyles.subHeadline)),
                  Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: _createParticipantTable(
                          organizerSessionState, libraryState)),
                  // Align(
                  //     alignment: Alignment.centerRight,
                  //     child: TextButton(
                  //         onPressed: () =>
                  //             SessionPairingAlgorithmTest().testAll(),
                  //         child: const Text('Test'))),
                  _createPairingTable(
                      context, organizerSessionState, libraryState),
                ],
              );
            }))));
  }

  _createParticipantTable(
      OrganizerSessionState organizerSessionState, LibraryState libraryState) {
    List<TableRow> tableRows = <TableRow>[];

    // Sort participants by admin, proficiency, and name.
    List<SessionParticipant> sessionParticipants =
        List.from(organizerSessionState.sessionParticipants);
    print('Number of participants: ${sessionParticipants.length}');
    sessionParticipants.sort((a, b) {
      // Put instructors on top.
      if (a.isInstructor) {
        return -1;
      } else if (b.isInstructor) {
        return 1;
      }

      // Otherwise sort by proficiency.
      Course? course = libraryState.selectedCourse;
      var userA = organizerSessionState.getUser(a);
      var userB = organizerSessionState.getUser(b);
      if (course != null) {
        double? proficiencyA = userA?.getCourseProficiency(course)?.proficiency;

        double? proficiencyB = userB?.getCourseProficiency(course)?.proficiency;

        if (proficiencyA != null && proficiencyB != null) {
          return proficiencyB.compareTo(proficiencyA);
        } else if (proficiencyA != null) {
          return -1;
        } else if (proficiencyB != null) {
          return 1;
        }
      }

      // Fall back to sorting by name.
      String? displayNameA = userA?.displayName.trim();
      String? displayNameB = userB?.displayName.trim();
      if ((displayNameA?.isNotEmpty ?? false) &&
          (displayNameB?.isNotEmpty ?? false)) {
        return displayNameA!.compareTo(displayNameB!);
      }

      return 0;
    });

    // Create header row.
    tableRows.add(TableRow(children: <Widget>[
      CustomUiConstants.getIndentationTextPadding(
          CustomUiConstants.getTextPadding(Text(
        'Name',
        style: CustomTextStyles.getBodyNote(context)
            ?.copyWith(fontWeight: FontWeight.bold),
      ))),
      // CustomUiConstants.getIndentationTextPadding(
      //     CustomUiConstants.getTextPadding(const Text('Role'))),
      Align(
          alignment: Alignment.centerRight,
          child: CustomUiConstants.getIndentationTextPadding(
              CustomUiConstants.getTextPadding(Text('Teaching Deficit',
                  style: CustomTextStyles.getBodyNote(context)
                      ?.copyWith(fontWeight: FontWeight.bold))))),
      Align(
          alignment: Alignment.centerRight,
          child: CustomUiConstants.getIndentationTextPadding(
              CustomUiConstants.getTextPadding(Text('Proficiency',
                  style: CustomTextStyles.getBodyNote(context)
                      ?.copyWith(fontWeight: FontWeight.bold))))),
    ]));

    // Separate active and inactive participants while preserving sort order.
    List<SessionParticipant> activeParticipants =
        sessionParticipants.where((p) => p.isActive).toList();
    List<SessionParticipant> inactiveParticipants =
        sessionParticipants.where((p) => !p.isActive).toList();

    // Helper to create a table row for a participant.
    TableRow buildParticipantRow(SessionParticipant sessionParticipant,
        {required bool isInactive}) {
      User? participantUser = organizerSessionState.getUser(sessionParticipant);

      var userId = sessionParticipant.participantId.id;
      int teachCount = organizerSessionState.getTeachCountForUser(userId);
      int learnCount = organizerSessionState.getLearnCountForUser(userId);
      int teachDeficit = teachCount - learnCount;
      Color teachDeficitColor =
          teachDeficit.abs() > 1 ? Colors.red : Colors.black;

      Course? course = libraryState.selectedCourse;
      double? proficiency = (course == null)
          ? null
          : participantUser?.getCourseProficiency(course)?.proficiency;

      String displayName = participantUser?.displayName ?? '';
      if (participantUser?.isAdmin ?? false) {
        displayName += ' (Instructor)';
      }

      TextStyle? inactiveStyle = CustomTextStyles.getBodyNote(context)
          ?.copyWith(color: Colors.grey, fontStyle: FontStyle.italic);

      return TableRow(children: <Widget>[
        CustomUiConstants.getIndentationTextPadding(
            Text(displayName, style: isInactive ? inactiveStyle : null)),
        CustomUiConstants.getIndentationTextPadding(Align(
            alignment: Alignment.centerRight,
            child: Text('$teachDeficit',
                style: (CustomTextStyles.getBodyNote(context)?.copyWith(
                    color: isInactive ? Colors.grey : teachDeficitColor,
                    fontStyle:
                        isInactive ? FontStyle.italic : FontStyle.normal))))),
        if (proficiency != null)
          CustomUiConstants.getIndentationTextPadding(Align(
              alignment: Alignment.centerRight,
              child: Text('${(proficiency * 100).round()}%',
                  style: (CustomTextStyles.getBodyNote(context)?.copyWith(
                      color: isInactive ? Colors.grey : null,
                      fontStyle:
                          isInactive ? FontStyle.italic : FontStyle.normal)))))
        else
          SizedBox.shrink()
      ]);
    }

    // Add active participant rows.
    for (SessionParticipant sessionParticipant in activeParticipants) {
      tableRows.add(buildParticipantRow(sessionParticipant, isInactive: false));
    }

    // Insert heading and inactive participant rows if any inactive participants.
    if (inactiveParticipants.isNotEmpty) {
      tableRows.add(TableRow(children: <Widget>[
        CustomUiConstants.getIndentationTextPadding(Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Text('Inactive Students',
                style: CustomTextStyles.getBodyNote(context)
                    ?.copyWith(fontWeight: FontWeight.bold)))),
        SizedBox.shrink(),
        SizedBox.shrink(),
      ]));

      for (SessionParticipant sessionParticipant in inactiveParticipants) {
        tableRows
            .add(buildParticipantRow(sessionParticipant, isInactive: true));
      }
    }

    return Table(columnWidths: const {
      0: FlexColumnWidth(),
      1: IntrinsicColumnWidth(),
      2: IntrinsicColumnWidth()
    }, children: tableRows);
  }

  Widget _createPairingTable(BuildContext context,
      OrganizerSessionState organizerSessionState, LibraryState libraryState) {
    var roundNumberToSessionPairing =
        organizerSessionState.roundNumberToSessionPairing;

    if (roundNumberToSessionPairing.isEmpty) {
      int studentCount = organizerSessionState.sessionParticipants
          .where((p) => !p.isInstructor && p.isActive)
          .length;
      String message;
      if (studentCount == 0) {
        message = 'Waiting for students to sign in.';
      } else {
        message =
            'Wait for all students to sign in.\n\nThen, click the button at the bottom right to pair the first round.';
      }
      return Padding(
          padding: EdgeInsets.only(top: 32),
          child: Center(
              child: CustomUiConstants.getTextPadding(Text(
            message,
            style: CustomTextStyles.getBody(context),
            textAlign: TextAlign.center,
          ))));
    }

    List<TableRow> tableRows = <TableRow>[];

    List<int> sortedRounds = roundNumberToSessionPairing.keys.toList()..sort();
    sortedRounds = sortedRounds.reversed.toList();

    for (int round in sortedRounds) {
      bool isCurrentRound = round == sortedRounds.first;

      tableRows.add(TableRow(
          decoration:
              BoxDecoration(color: CustomUiConstants.accentedBackgroundColor),
          children: <Widget>[
            // TODO: Set dark background color and span the whole row.
            CustomUiConstants.getIndentationTextPadding(
              Text('Round ${round + 1}', style: CustomTextStyles.subHeadline),
            ),
            SizedBox.shrink(),
            SizedBox.shrink(),
          ]));
      tableRows.add(TableRow(children: <Widget>[
        CustomUiConstants.getIndentationTextPadding(
            CustomUiConstants.getTextPadding(const Text('Mentor'))),
        CustomUiConstants.getIndentationTextPadding(
            CustomUiConstants.getTextPadding(const Text('Mentee'))),
        CustomUiConstants.getIndentationTextPadding(
            CustomUiConstants.getTextPadding(const Text('Lesson'))),
      ]));

      List<SessionPairing> sessionPairings =
          roundNumberToSessionPairing[round]!;
      for (SessionPairing sessionPairing in sessionPairings) {
        print('mentorId = ${sessionPairing.mentorId?.id}');
        User? mentor =
            organizerSessionState.getUserById(sessionPairing.mentorId?.id);
        User? mentee =
            organizerSessionState.getUserById(sessionPairing.menteeId?.id);
        Lesson? lesson = libraryState.findLesson(sessionPairing.lessonId?.id);

        tableRows.add(TableRow(children: <Widget>[
          MentorTableCell(mentor, sessionPairing, isCurrentRound,
              'Select Mentor', lesson, organizerSessionState),
          MenteeTableCell(mentee, sessionPairing, isCurrentRound,
              'Select Mentee', lesson, organizerSessionState),
          LessonTableCell(lesson, mentor, mentee, sessionPairing,
              isCurrentRound, 'Select Lesson', organizerSessionState),
        ]));
      }
    }

    return Table(columnWidths: const {
      0: FlexColumnWidth(),
      1: FlexColumnWidth(),
      2: FlexColumnWidth()
    }, children: tableRows);
  }

  _pairNextRound(BuildContext context) {
    OrganizerSessionState organizerSessionState =
        Provider.of<OrganizerSessionState>(context, listen: false);

    // Close the current round.
    organizerSessionState.endCurrentRound();

    // Match students.
    var libraryState = Provider.of<LibraryState>(context, listen: false);
    PairedSession pairedSession = SessionPairingAlgorithm()
        .generateNextSessionPairing(organizerSessionState, libraryState);

    // Save next round to the Firestore.
    organizerSessionState.saveNextRound(pairedSession);
  }

  _endSession(BuildContext context) {
    DialogUtils.showConfirmationDialog(
        context, 'End Session', 'Are you sure you want to end the session?',
        () {
      OrganizerSessionState organizerSessionState =
          Provider.of<OrganizerSessionState>(context, listen: false);

      organizerSessionState.endSession();

      print('The session has ended. Going to the level list page.');
      Navigator.pushNamed(context, NavigationEnum.levelList.route);
    });
  }
}
