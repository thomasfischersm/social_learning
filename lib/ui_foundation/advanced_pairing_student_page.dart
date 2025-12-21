import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
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
        },
        child: const Icon(Icons.exit_to_app, color: Colors.grey),
      ),
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

  Widget _buildPairingCards(
    StudentSessionState studentSessionState,
    LibraryState libraryState,
    ApplicationState applicationState,
    StudentState studentState,
  ) {
    String? currentUserId = applicationState.currentUser?.id;
    List<SessionPairing> allPairings = studentSessionState.allPairings;

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
      final bool showLearnerProgress = isCurrentRound &&
          (studentSessionState.currentSession?.isActive ?? false) &&
          lesson != null &&
          studentState.hasGraduated(lesson);

      cards.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: AdvancedPairingStudentCard(
            roundNumber: relevantPairings.indexOf(pairing) + 1,
            lesson: lesson,
            mentor: mentor,
            learners: learners,
            showLearnerProgress: showLearnerProgress,
            currentUserId: applicationState.currentUser?.id,
          ),
        ),
      );
    }

    return Column(children: cards);
  }
}

