import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/data_helpers/online_session_functions.dart';
import 'package:social_learning/data/online_session.dart';
import 'package:social_learning/data/session.dart';
import 'package:social_learning/state/available_session_state.dart';
import 'package:social_learning/ui_foundation/bottom_bar.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/custom_card.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';
import 'package:social_learning/ui_foundation/session_student_page.dart';

class SessionHomePage extends StatefulWidget {
  const SessionHomePage({super.key});

  @override
  SessionHomePageState createState() => SessionHomePageState();
}

class SessionHomePageState extends State<SessionHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Lab'),
      ),
      bottomNavigationBar: BottomBarV2.build(context),
      body: CustomUiConstants.framePage(
        enableScrolling: false,
        Column(
          children: [
            // Top section: scrollable in-person sessions.
            Flexible(flex: 1, child: const InPersonSessionSection()),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            // Bottom section: online session section (fixed at bottom).
            if (false) Flexible(flex: 1, child: const OnlineSessionSection()),
          ],
        ),
      ),
    );
  }
}

class InPersonSessionSection extends StatelessWidget {
  const InPersonSessionSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      title: 'In-Person Group Sessions',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Join a group session led by an instructor or practice meetup.',
            style: CustomTextStyles.getBody(context),
          ),
          const SizedBox(height: 8),
          Consumer<AvailableSessionState>(
            builder: (context, availableSessionState, child) =>
                _buildAvailableSessions(context, availableSessionState),
          ),
          CustomUiConstants.getDivider(),
          Row(
            children: [
              const Spacer(),
              ElevatedButton(
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
    );
  }

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
          onTap: () => _joinSession(session, context),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(sessionLabel, style: CustomTextStyles.getBody(context)),
          ),
        );
      }).toList(),
    );
  }

  void _joinSession(Session session, BuildContext context) {
    if (session.id != null) {
      Navigator.pushNamed(
        context,
        NavigationEnum.sessionStudent.route,
        arguments: SessionStudentArgument(session.id!),
      );
    }
  }
}

class OnlineSessionSection extends StatefulWidget {
  const OnlineSessionSection({super.key});

  @override
  OnlineSessionSectionState createState() => OnlineSessionSectionState();
}

class OnlineSessionSectionState extends State<OnlineSessionSection> {
  bool _isWaiting = false;
  String _waitingMessage = '';

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
              Column(
                children: [
                  ElevatedButton(
                    onPressed: _onTeachNowPressed,
                    child: const Text(
                      'Teach Now',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Waiting count for learners
                  const WaitingCountWidget(waitingRole: WaitingRole.learner),
                ],
              ),
              // Learn Now column: shows count of mentors waiting.
              Column(
                children: [
                  ElevatedButton(
                    onPressed: _onLearnNowPressed,
                    child: const Text(
                      'Learn Now',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Waiting count for mentors
                  const WaitingCountWidget(waitingRole: WaitingRole.mentor),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isWaiting)
            Center(
              child: Text(
                _waitingMessage,
                style: CustomTextStyles.getBody(context),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  void _onTeachNowPressed() {
    // TODO: Integrate your Firestore helper to create an online session as a mentor.
    setState(() {
      _isWaiting = true;
      _waitingMessage =
          'You are now in the waiting room as a mentor.\nPlease wait for a learner.';
    });
  }

  void _onLearnNowPressed() {
    // TODO: Integrate your Firestore helper to create an online session as a learner.
    setState(() {
      _isWaiting = true;
      _waitingMessage =
          'You are now in the waiting room as a learner.\nPlease wait for a mentor.';
    });
  }
}

enum WaitingRole {
  learner, // Waiting for a learner (sessions initiated by a mentor)
  mentor, // Waiting for a mentor (sessions initiated by a learner)
}

class WaitingCountWidget extends StatelessWidget {
  final WaitingRole waitingRole;

  const WaitingCountWidget({
    super.key,
    required this.waitingRole,
  });

  @override
  Widget build(BuildContext context) {
    final Stream<List<OnlineSession>> stream;
    final String roleLabel;
    if (waitingRole == WaitingRole.learner) {
      stream = OnlineSessionFunctions.listenSessionsAwaitingLearner();
      roleLabel = 'learner';
    } else {
      stream = OnlineSessionFunctions.listenSessionsAwaitingMentor();
      roleLabel = 'mentor';
    }
    return StreamBuilder<List<OnlineSession>>(
      stream: stream,
      builder: (context, snapshot) {
        int count = snapshot.hasData ? snapshot.data!.length : 0;
        String displayText = count > 0
            ? '$count $roleLabel${count > 1 ? 's' : ''} waiting'
            : '';
        return Text(
          displayText,
          style: CustomTextStyles.getBody(context),
        );
      },
    );
  }
}
