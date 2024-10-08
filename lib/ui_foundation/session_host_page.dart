import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/data_helpers/belt_color_functions.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/session_pairing.dart';
import 'package:social_learning/data/session_participant.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/session_pairing/paired_session.dart';
import 'package:social_learning/session_pairing/session_pairing_algorithm.dart';
import 'package:social_learning/session_pairing/testing/session_pairing_algorithm_test.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/organizer_session_state.dart';
import 'package:social_learning/ui_foundation/bottom_bar.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/other_profile_page.dart';
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
        body: Align(
            alignment: Alignment.topCenter,
            child: CustomUiConstants.framePage(Consumer<OrganizerSessionState>(
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
                    _createParticipantTable(
                        organizerSessionState, libraryState),
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
                                () => _endSession(
                                    context, organizerSessionState)),
                            child: const Text('End the session'))),
                    // Align(
                    //     alignment: Alignment.centerRight,
                    //     child: TextButton(
                    //         onPressed: () =>
                    //             SessionPairingAlgorithmTest().testAll(),
                    //         child: const Text('Test'))),
                    _createPairingTable(organizerSessionState, libraryState),
                  ],
                );
              });
            }))));
  }

  _createParticipantTable(
      OrganizerSessionState organizerSessionState, LibraryState libraryState) {
    List<TableRow> tableRows = <TableRow>[];

    // Sort participants by admin, proficiency, and name.
    List<SessionParticipant> sessionParticipants =
        List.from(organizerSessionState.sessionParticipants);
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

    for (SessionParticipant sessionParticipant in sessionParticipants) {
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
      // Color? proficiencyColor = (proficiency == null)
      //     ? null
      //     : BeltColorFunctions.getBeltColor(proficiency);
      // Color? proficiencyTextColor = (proficiencyColor == null)
      //     ? null
      //     : ((proficiencyColor.computeLuminance() > 0.5)
      //         ? Colors.black
      //         : Colors.white);

      String displayName = participantUser?.displayName ?? '';
      if (participantUser?.isAdmin ?? false) {
        displayName += ' (Instructor)';
      }

      tableRows.add(TableRow(children: <Widget>[
        CustomUiConstants.getIndentationTextPadding(Text(displayName)),
        // CustomUiConstants.getIndentationTextPadding(
        //     Text(sessionParticipant.isInstructor ? 'Instructor' : 'Student')),
        CustomUiConstants.getIndentationTextPadding(Align(
            alignment: Alignment.centerRight,
            child: Text('$teachDeficit',
                style: CustomTextStyles.getBody(context)
                    ?.copyWith(color: teachDeficitColor)))),
        if (proficiency != null)
          CustomUiConstants.getIndentationTextPadding(Align(
              alignment: Alignment.centerRight,
              child: Text('${(proficiency * 100).round()}%',
                  style: CustomTextStyles.getBody(
                      context) /*?.copyWith(color: proficiencyTextColor)*/)))
        else
          SizedBox.shrink()
      ]));
    }

    return Table(columnWidths: const {
      0: FlexColumnWidth(),
      1: IntrinsicColumnWidth(),
      2: IntrinsicColumnWidth()
    }, children: tableRows);
  }

  Table _createPairingTable(
      OrganizerSessionState organizerSessionState, LibraryState libraryState) {
    List<TableRow> tableRows = <TableRow>[];

    var roundNumberToSessionPairing =
        organizerSessionState.roundNumberToSessionPairing;
    List<int> sortedRounds = roundNumberToSessionPairing.keys.toList()..sort();
    sortedRounds = sortedRounds.reversed.toList();

    for (int round in sortedRounds) {
      tableRows.add(TableRow(
          decoration:
              BoxDecoration(color: CustomUiConstants.accentedBackgroundColor),
          children: <Widget>[
            // TODO: Set dark background color and span the whole row.
            CustomUiConstants.getIndentationTextPadding(
              Text('Session ${round + 1}', style: CustomTextStyles.subHeadline),
            ),
            SizedBox.shrink(),
            SizedBox.shrink(),
          ]));
      tableRows.add(TableRow(children: <Widget>[
        CustomUiConstants.getIndentationTextPadding(
            CustomUiConstants.getTextPadding(const Text('Mentor'))),
        CustomUiConstants.getIndentationTextPadding(
            CustomUiConstants.getTextPadding(const Text('Mentee'))),
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
          Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 8),
              child: (InkWell(
                  onTap: () => _goToProfile(mentor),
                  child: Text(mentor?.displayName ?? 'Error!!!')))),
          Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 8),
              child: (InkWell(
                  onTap: () => _goToProfile(mentee),
                  child: Text(mentee?.displayName ?? 'Error!!!')))),
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
    // Close the current round.
    organizerSessionState.endCurrentRound();

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

  _goToProfile(User? user) {
    if (user != null) {
      ApplicationState applicationState =
          Provider.of<ApplicationState>(context, listen: false);
      User? currentUser = applicationState.currentUser;
      if (currentUser?.id == user.id) {
        // Don't go to your own profile.
        return;
      }

      OtherProfileArgument.goToOtherProfile(context, user.id, user.uid);
    }
  }
}
