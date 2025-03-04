import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/data_helpers/online_session_functions.dart';
import 'package:social_learning/data/data_helpers/practice_record_functions.dart';
import 'package:social_learning/data/data_helpers/reference_helper.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/online_session.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/online_session_state.dart';
import 'package:social_learning/state/student_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/custom_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/session_widgets/online_session_section.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

class OnlineSessionSection extends StatefulWidget {
  const OnlineSessionSection({super.key});

  @override
  OnlineSessionSectionState createState() => OnlineSessionSectionState();
}

class OnlineSessionSectionState extends State<OnlineSessionSection> {
  @override
  Widget build(BuildContext context) {
    // Make sure to init StudentState, in case the user went directly to this
    // page.
    StudentState studentState = Provider.of<StudentState>(context, listen: false);
    studentState.getGraduatedLessonIds();

    return CustomCard(
      title: 'Immediate 1:1 Online Sessions',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'To learn or mentor now via video chat, choose an option below:',
            style: CustomTextStyles.getBody(context),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Teach Now column: shows count of learners waiting.
              OnlineSessionInitiationWidget(
                waitingRole: WaitingRole.waitingForLearner,
                onClick: _onTeachNowPressed,
              ),
              // Learn Now column: shows count of mentors waiting.
              OnlineSessionInitiationWidget(
                  waitingRole: WaitingRole.waitingForMentor,
                  onClick: _onLearnNowPressed),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _onTeachNowPressed(List<OnlineSession>? sessionQueue) async {
    print('Teach Now pressed. Queue size: ${sessionQueue?.length}');
    if (sessionQueue != null) {
      OnlineSession? newSession =
          await OnlineSessionFunctions.tryPairWithWaitingSession(
              sessionQueue, WaitingRole.waitingForLearner, context);
      if (newSession != null) {
        // Redirect to the active session page.
        if (mounted) {
          Navigator.pushNamed(
              context, NavigationEnum.onlineSessionActive.route);
          return;
        }
      }
    }

    handleSessionCreation(context, WaitingRole.waitingForLearner);
  }

  void _onLearnNowPressed(List<OnlineSession>? sessionQueue) async {
    if (sessionQueue != null) {
      OnlineSession? newSession =
          await OnlineSessionFunctions.tryPairWithWaitingSession(
              sessionQueue, WaitingRole.waitingForMentor, context);
      if (newSession != null) {
        // Redirect to the active session page.
        if (mounted) {
          Navigator.pushNamed(
              context, NavigationEnum.onlineSessionActive.route);
          return;
        }
      }
    }

    handleSessionCreation(context, WaitingRole.waitingForMentor);
  }

  /// Shows a modal dialog that asks the user for a video chat URL.
  /// Only URLs containing "meet.google.com" or "zoom.us" are considered valid.
  /// The dialog title and instructions vary depending on the [waitingRole].
  Future<String?> showVideoUrlDialog(
    BuildContext context,
    WaitingRole waitingRole,
  ) {
    final TextEditingController _controller = TextEditingController();
    final _formKey = GlobalKey<FormState>();
    bool isValid = false;

    return showDialog<String>(
      context: context,
      barrierDismissible: false, // Force the user to choose Cancel or confirm.
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          String? _validateMeetingUrl(String? value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a URL';
            }

            final uri = Uri.tryParse(value);
            if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
              return 'Invalid URL';
            }
            if (uri.scheme != 'https') {
              return 'URL must start with https';
            }

            final host = uri.host.toLowerCase();
            // Check for Google Meet
            if (host == 'meet.google.com') return null;
            // Check for Zoom: allow zoom.us and its subdomains (e.g., us02web.zoom.us)
            if (host == 'zoom.us' || host.endsWith('.zoom.us')) return null;

            return 'URL must be a Google Meet or Zoom link';
          }

          return AlertDialog(
            title: Text(
              waitingRole == WaitingRole.waitingForLearner
                  ? 'Set Up Your Teaching Session'
                  : 'Set Up Your Learning Session',
            ),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(
                '1. Create a video chat.\n'
                '2. Copy the URL from your browser.\n'
                '3. Wait for another student to join.',
                style: CustomTextStyles.getBody(context),
              ),
              SizedBox(
                height: 4,
              ),
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'https://meet.google.com/… or https://zoom.us/…',
                  ),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: _validateMeetingUrl,
                  onChanged: (value) {
                    setState(() {
                      isValid = _formKey.currentState?.validate() ?? false;
                    });
                  },
                ),
              ),
            ]),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(null); // User cancelled.
                },
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: isValid
                    ? () {
                        if (_formKey.currentState?.validate() ?? false) {
                          Navigator.of(context).pop(_controller.text);
                        }
                      }
                    : null,
                child: Text('Start Session'),
              ),
            ],
          );
        });
      },
    );
  }

  /// Handles the use case when the user taps either "I want to teach" or "I want to learn".
  /// It shows the URL input dialog, creates an online session in Firestore,
  /// and navigates to the waiting room page.
  Future<void> handleSessionCreation(
    BuildContext context,
    WaitingRole waitingRole,
  ) async {
    // Open the dialog to collect the video chat URL.
    String? meetingUrl = await showVideoUrlDialog(context, waitingRole);
    if (meetingUrl == null) {
      // User cancelled the dialog.
      return;
    }

    // Determine the isMentorInitiated flag.
    // According to your enum:
    // - WaitingRole.learner: session initiated by a mentor (i.e., teacher wants to teach).
    // - WaitingRole.mentor: session initiated by a learner (i.e., learner wants to learn).
    bool isMentorInitiated = waitingRole == WaitingRole.waitingForLearner;

    // Get the current user's document reference.
    // Replace the following with your actual user reference retrieval logic.
    ApplicationState appState =
        Provider.of<ApplicationState>(context, listen: false);
    String currentUserUid = appState.currentUser!.uid;

    LibraryState libraryState =
        Provider.of<LibraryState>(context, listen: false);
    String? courseId = libraryState.selectedCourse?.id;

    // Set the appropriate user fields.
    // NOTE: The OnlineSession constructor requires a learnerUid.
    // For a teacher-initiated session (isMentorInitiated == true), the teacher is the mentor.
    // In this simplified example, we pass the currentUserUid for both fields.
    String? learnerUid;
    String? mentorUid;
    if (isMentorInitiated) {
      mentorUid = currentUserUid;
      learnerUid = null;
    } else {
      learnerUid = currentUserUid;
      mentorUid = null;
    }

    // Create a new OnlineSession instance.
    OnlineSession newSession = OnlineSession(
      courseId: docRef('courses', courseId!),
      learnerUid: learnerUid,
      mentorUid: mentorUid,
      videoCallUrl: meetingUrl,
      isMentorInitiated: isMentorInitiated,
      status: OnlineSessionStatus.waiting,
      created: null,
      lastActive: null,
      pairedAt: null,
      lessonId: null,
    );

    // Create the session document in Firestore.
    DocumentReference sessionDocRef =
        await OnlineSessionFunctions.createOnlineSession(newSession);
    newSession.id = sessionDocRef.id;

    // Update SessionState.
    OnlineSessionState onlineSessionState =
        Provider.of<OnlineSessionState>(context, listen: false);
    var session = await OnlineSessionFunctions.getOnlineSession(newSession.id!);
    onlineSessionState.setWaitingSession(session);

    // Redirect to the waiting room page.
    if (mounted) {
      setState(() {
        Navigator.pushNamed(
            context, NavigationEnum.onlineSessionWaitingRoom.route);
      });
    }
  }
}

class OnlineSessionInitiationWidget extends StatelessWidget {
  final WaitingRole waitingRole;
  final OnlineInitiationCallback onClick;

  const OnlineSessionInitiationWidget({
    super.key,
    required this.waitingRole,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    final Stream<List<OnlineSession>> stream;
    final String roleLabel;
    final String buttonLabel;
    if (waitingRole == WaitingRole.waitingForLearner) {
      stream = OnlineSessionFunctions.listenSessionsAwaitingMentor(context);
      roleLabel = 'learner';
      buttonLabel = 'Teach Now';
    } else {
      stream = OnlineSessionFunctions.listenSessionsAwaitingLearner(context);
      roleLabel = 'mentor';
      buttonLabel = 'Learn Now';
    }
    return StreamBuilder<List<OnlineSession>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('${snapshot.error}');
        }
        int count = snapshot.hasData ? snapshot.data!.length : 0;
        String displayText =
            count > 0 ? '$count $roleLabel${count > 1 ? 's' : ''} waiting' : '';

        print('Check sessions for $waitingRole role: $count');

        return Column(
          children: [
            ElevatedButton(
              onPressed: () => onClick(snapshot.data),
              child: Text(
                buttonLabel,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
            const SizedBox(height: 4),
            // Waiting count for learners
            Text(
              displayText,
              style: CustomTextStyles.getBody(context),
            ),
          ],
        );
      },
    );
  }
}

typedef OnlineInitiationCallback = void Function(
    List<OnlineSession>? sessionQueue);
