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
import 'package:social_learning/state/student_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/custom_card.dart';
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
    if (sessionQueue != null) {
      OnlineSession? newSession = await tryPairWithWaitingSession(
          waitingSessions: sessionQueue,
          waitingRole: WaitingRole.waitingForLearner);
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
      OnlineSession? newSession = await tryPairWithWaitingSession(
          waitingSessions: sessionQueue,
          waitingRole: WaitingRole.waitingForMentor);
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
          // Validation function for the URL.
          String? _validateUrl(String? value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a URL';
            }
            if (!value.contains('meet.google.com') &&
                !value.contains('zoom.us')) {
              return 'URL must be a Google Meet or Zoom link';
            }
            return null;
          }

          return AlertDialog(
            title: Text(
              waitingRole == WaitingRole.waitingForLearner
                  ? 'Set Up Your Teaching Session'
                  : 'Set Up Your Learning Session',
            ),
            content: Form(
              key: _formKey,
              child: TextFormField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'https://meet.google.com/… or https://zoom.us/…',
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: _validateUrl,
                onChanged: (value) {
                  setState(() {
                    isValid = _formKey.currentState?.validate() ?? false;
                  });
                },
              ),
            ),
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

    // Redirect to the waiting room page.
    if (mounted) {
      Navigator.pushNamed(
          context, NavigationEnum.onlineSessionWaitingRoom.route);
    }
  }

  /// Tries to pair the current user with a waiting session.
  ///
  /// [waitingSessions]: The list of waiting sessions (already converted to OnlineSession).
  /// [waitingRole]: The current user's role:
  ///   - WaitingRole.learner: current user is a learner, so join a session initiated by a mentor.
  ///   - WaitingRole.mentor: current user is a mentor, so join a session initiated by a learner.
  /// [currentUserRef]: The Firestore DocumentReference for the current user.
  /// [canPartner]: A function that, given an OnlineSession, determines if the current user can
  ///    learn/teach from that session. It returns a DocumentReference for the lessonId if it’s a good match,
  ///    or null if not.
  ///
  /// Returns the updated OnlineSession if pairing was successful, or null if no suitable partner was found.
  Future<OnlineSession?> tryPairWithWaitingSession({
    required List<OnlineSession> waitingSessions,
    required WaitingRole waitingRole,
    // required DocumentReference currentUserRef,
    // required Future<DocumentReference?> Function(OnlineSession session) canPartner,
  }) async {
    DateTime now = DateTime.now();
    // Determine the cutoff time for an active session.
    DateTime validSince =
        now.subtract(OnlineSessionFunctions.HEARTBEAT_EXPIRATION);

    // Filter out sessions that are inactive (i.e. lastActive is too old).
    List<OnlineSession> activeSessions = waitingSessions.where((session) {
      if (session.lastActive == null) return false;
      DateTime lastActive = session.lastActive!.toDate();
      return lastActive.isAfter(validSince) &&
          session.status == OnlineSessionStatus.waiting;
    }).toList();

    // Filter sessions based on the current user's role.
    // For a learner (waitingRole.learner): we need sessions initiated by a mentor.
    // For a mentor (waitingRole.mentor): we need sessions initiated by a learner.
    activeSessions = activeSessions.where((session) {
      return waitingRole == WaitingRole.waitingForLearner
          ? session.isMentorInitiated
          : !session.isMentorInitiated;
    }).toList();

    // Sort the sessions by creation time (oldest first) so that the one on top of the queue is picked.
    activeSessions.sort((a, b) {
      DateTime aCreated = a.created?.toDate() ?? now;
      DateTime bCreated = b.created?.toDate() ?? now;
      return aCreated.compareTo(bCreated);
    });

    // Iterate over the eligible sessions.
    for (OnlineSession session in activeSessions) {
      // Ask the external method if the current user can partner on this session.
      DocumentReference? lessonRef = await canPartner(session);
      if (lessonRef != null) {
        // A good match is found. Build the update data.

        // Depending on the user's role, update the corresponding participant field.
        ApplicationState appState =
            Provider.of<ApplicationState>(context, listen: false);
        String currentUserUid = appState.currentUser!.uid;
        if (waitingRole == WaitingRole.waitingForLearner) {
          // Current user is a learner joining a session initiated by a mentor.
          await OnlineSessionFunctions.updateSessionWithMatch(
              sessionId: session.id!,
              learnerUid: currentUserUid,
              lessonRef: lessonRef);
        } else {
          // Current user is a mentor joining a session initiated by a learner.
          await OnlineSessionFunctions.updateSessionWithMatch(
              sessionId: session.id!,
              mentorUid: currentUserUid,
              lessonRef: lessonRef);
        }

        // // Reflect the changes in our session instance.
        // session.status = OnlineSessionStatus.active;
        // session.pairedAt = Timestamp.now();
        // // Here, we store the lessonId as the document id (or adjust as needed).
        // session.lessonId = lessonRef.id;
        // if (waitingRole == WaitingRole.waitingForLearner) {
        //   session.learnerId = currentUserRef;
        // } else {
        //   session.mentorId = currentUserRef;
        // }

        return session;
      }
      // If not a good match, proceed to the next session in the queue.
    }

    // No suitable partner was found.
    return null;
  }

  Future<DocumentReference?> canPartner(OnlineSession session) async {
    ApplicationState applicationState =
        Provider.of<ApplicationState>(context, listen: false);
    LibraryState libraryState =
        Provider.of<LibraryState>(context, listen: false);
    StudentState studentState =
        Provider.of<StudentState>(context, listen: false);

    // Get uids.
    String thisStudentUid = applicationState.currentUser!.uid;
    String otherStudentUid =
        session.isMentorInitiated ? session.mentorUid! : session.learnerUid!;

    // Get lessons learned for the current user.
    List<String> thisStudentLessonIds = studentState.getGraduatedLessonIds();

    // Get learned lessons for the other user.
    List<String> otherStudentLessonIds =
        (await PracticeRecordFunctions.getLearnedLessonIds(otherStudentUid))
            .map((e) => e.id)
            .toList();

    // Find the first good lesson.
    Set<String> mentorLessonIds = (session.isMentorInitiated
            ? otherStudentLessonIds
            : thisStudentLessonIds)
        .toSet();
    Set<String> learnerLessonIds = (session.isMentorInitiated
            ? thisStudentLessonIds
            : otherStudentLessonIds)
        .toSet();

    List<Lesson>? lessons = libraryState.lessons;
    if (lessons != null) {
      for (Lesson lesson in lessons) {
        if (mentorLessonIds.contains(lesson.id) &&
            learnerLessonIds.contains(lesson.id)) {
          return docRef('lessons', lesson.id!);
        }
      }
    }

    return null;
  }
}

enum WaitingRole {
  waitingForLearner, // Waiting for a learner (sessions initiated by a mentor)
  waitingForMentor, // Waiting for a mentor (sessions initiated by a learner)
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
      stream = OnlineSessionFunctions.listenSessionsAwaitingLearner(context);
      roleLabel = 'learner';
      buttonLabel = 'Teach Now';
    } else {
      stream = OnlineSessionFunctions.listenSessionsAwaitingMentor(context);
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
