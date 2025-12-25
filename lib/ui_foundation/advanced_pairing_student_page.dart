import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/session_pairing.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/student_session_state.dart';
import 'package:social_learning/state/student_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/advanced_pairing_student/advanced_pairing_student_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/dialog_utils.dart';
import 'package:social_learning/ui_foundation/helper_widgets/general/background_image_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/general/background_image_style.dart';
import 'package:social_learning/ui_foundation/helper_widgets/general/learning_lab_app_bar.dart';
import 'package:social_learning/ui_foundation/helper_widgets/user_profile_widgets/profile_image_widget_v2.dart';
import 'package:social_learning/ui_foundation/lesson_detail_page.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';

class AdvancedPairingStudentArgument {
  final String sessionId;

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
      floatingActionButton: _buildFloatingActionButton(context),
      body: Align(
        alignment: Alignment.topCenter,
        child: CustomUiConstants.framePage(
          Consumer4<ApplicationState, LibraryState, StudentSessionState,
              StudentState>(builder: (context, applicationState, libraryState,
                  studentSessionState, studentState, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (studentSessionState.currentSession?.isActive == false)
                  CustomUiConstants.getTextPadding(
                    Text('The session has ended!',
                        style: CustomTextStyles.subHeadline),
                  ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Session: ${studentSessionState.currentSession?.name ?? ''}',
                      style: CustomTextStyles.headline,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                _buildPairingCards(
                  studentSessionState,
                  libraryState,
                  applicationState,
                  studentState,
                ),
              ],
            );
          },
        ),
      ),
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return Consumer2<ApplicationState, StudentSessionState>(
      builder: (context, applicationState, studentSessionState, child) {
        final isMentoringActiveRound = _isMentoringActiveRound(
          applicationState,
          studentSessionState,
        );

        if (!isMentoringActiveRound) {
          return _buildLeaveSessionButton(context);
        }

        return SpeedDial(
          icon: Icons.more_vert,
          activeIcon: Icons.close,
          children: [
            SpeedDialChild(
              onTap: () => _finishRound(context, studentSessionState),
              child: const Icon(Icons.flag, color: Colors.grey),
              label: 'Finish round',
            ),
            SpeedDialChild(
              onTap: () => _confirmLeaveSession(context),
              child: const Icon(Icons.exit_to_app, color: Colors.grey),
              label: 'Leave session',
            ),
          ],
        );
      },
    );
  }

  Widget _buildLeaveSessionButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _confirmLeaveSession(context),
      child: const Icon(Icons.exit_to_app, color: Colors.grey),
    );
  }

  void _confirmLeaveSession(BuildContext context) {
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
  }

  void _finishRound(
    BuildContext context,
    StudentSessionState studentSessionState,
  ) {
    DialogUtils.showConfirmationDialog(
      context,
      'Finish Round',
      'Are you sure you want to finish this round?',
      () => studentSessionState.completeCurrentPairing(),
    );
  }

  bool _isMentoringActiveRound(
    ApplicationState applicationState,
    StudentSessionState studentSessionState,
  ) {
    final currentUserId = applicationState.currentUser?.id;
    final currentPairing = studentSessionState.currentPairing;

    if (currentUserId == null || currentPairing == null) {
      return false;
    }

    return currentPairing.mentorId?.id == currentUserId &&
        !currentPairing.isCompleted;
  }

  Widget _buildPairingCards(
    StudentSessionState studentSessionState,
    LibraryState libraryState,
    ApplicationState applicationState,
    StudentState studentState,
  ) {
    String? currentUserId = applicationState.currentUser?.id;
    List<SessionPairing> allPairings = studentSessionState.allPairings;

    if (studentSessionState.currentSession == null) {
      return Column(
        children: [
          CustomUiConstants.getTextPadding(
            Text(
              'The session has ended.',
              style: CustomTextStyles.getBody(context),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }
    if (currentUserId == null || allPairings.isEmpty) {
      return Column(
        children: [
          CustomUiConstants.getTextPadding(
            Text(
              'Waiting for the instructor to create the first pairing.',
              style: CustomTextStyles.getBody(context),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    List<SessionPairing> relevantPairings = [];
    for (SessionPairing pairing in allPairings) {
      bool isCurrentUser = (pairing.mentorId?.id == currentUserId) ||
          (pairing.menteeId?.id == currentUserId) ||
          pairing.additionalStudentIds.any((ref) => ref.id == currentUserId);
      if (isCurrentUser) {
        relevantPairings.add(pairing);
      }
    }

    if (relevantPairings.isEmpty) {
      return Column(
        children: [
          CustomUiConstants.getTextPadding(
            Text(
              'Waiting for the instructor to create the first pairing.',
              style: CustomTextStyles.getBody(context),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    relevantPairings.sort(
        (a, b) => b.roundNumber.compareTo(a.roundNumber)); // Latest first.

    List<Widget> cards = [];
    for (final pairing in relevantPairings) {
      final lessonId = pairing.lessonId?.id;
      final lesson = (lessonId == null)
          ? null
          : libraryState.findLesson(lessonId);

      final mentor = studentSessionState.getUserById(pairing.mentorId?.id);
      final mentee = studentSessionState.getUserById(pairing.menteeId?.id);

      final learners = <User?>[mentee];
      for (final additionalStudentId in pairing.additionalStudentIds) {
        learners.add(studentSessionState.getUserById(additionalStudentId.id));
      }

      final bool isCurrentRound = pairing == relevantPairings.first;
      // Note: Any student, not only the mentor can graduate students (if they
      // have graduated the lesson themselves).
      final bool showGraduationCheckboxes = isCurrentRound &&
          (studentSessionState.currentSession?.isActive ?? false) &&
          lesson != null &&
          studentState.hasGraduated(lesson);

      cards.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: AdvancedPairingStudentCard(
            // Show rounds relative to how they appear to the user because the
            // absolute round numbers make no sense from a student perspective.
            roundNumber: relevantPairings.length - relevantPairings.indexOf(pairing),
            lesson: lesson,
            mentor: mentor,
            learners: learners,
            showGraduationCheckboxes: showGraduationCheckboxes,
          ),
        ),
      );
    }

    return Column(children: cards);
  }
}

