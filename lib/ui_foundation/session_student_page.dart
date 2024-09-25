import 'package:social_learning/data/user.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/session_pairing.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/student_session_state.dart';
import 'package:social_learning/ui_foundation/bottom_bar.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants//custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/lesson_detail_page.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

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
  Widget build(BuildContext context) {
    SessionStudentArgument? argument =
        ModalRoute.of(context)!.settings.arguments as SessionStudentArgument?;
    if (argument != null) {
      String sessionId = argument.sessionId;
      var studentSessionState =
          Provider.of<StudentSessionState>(context, listen: false);
      studentSessionState.attemptToJoin(sessionId);
    }

    return Scaffold(
        appBar: AppBar(title: const Text('Learning Lab')),
        bottomNavigationBar: BottomBarV2.build(context),
        body: Center(child: CustomUiConstants.framePage(
            Consumer<ApplicationState>(
                builder: (context, applicationState, child) {
          return Consumer<LibraryState>(
              builder: (context, libraryState, child) {
            return Consumer<StudentSessionState>(
                builder: (context, studentSessionState, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (studentSessionState.currentSession?.isActive == false)
                    CustomUiConstants.getTextPadding(Text(
                        'The session has ended!',
                        style: CustomTextStyles.subHeadline)),
                  CustomUiConstants.getTextPadding(Text(
                      'Attending Session: ${studentSessionState.currentSession?.name}',
                      style: CustomTextStyles.subHeadline)),
                  _createPairingTable(
                      studentSessionState, libraryState, applicationState),
                ],
              );
            });
          });
        }))));
  }

  Table _createPairingTable(StudentSessionState studentSessionState,
      LibraryState libraryState, ApplicationState applicationState) {
    List<TableRow> tableRows = <TableRow>[];

    String? currentUserId = applicationState.currentUser?.id;

    var roundNumberToSessionPairing =
        studentSessionState.roundNumberToSessionPairing;
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
            studentSessionState.getUserById(sessionPairing.mentorId.id);
        User? mentee =
            studentSessionState.getUserById(sessionPairing.menteeId.id);
        Lesson? lesson = libraryState.findLesson(sessionPairing.lessonId.id);

        if ((mentor?.id != currentUserId) && (mentee?.id != currentUserId)) {
          // Only show pairings if the involve the current student.
          continue;
        }

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

  _goToLesson(Lesson? lesson) {
    String? lessonId = lesson?.id;
    if (lessonId != null) {
      Navigator.pushNamed(context, NavigationEnum.lessonDetail.route,
          arguments: LessonDetailArgument(lessonId));
    }
  }
}
