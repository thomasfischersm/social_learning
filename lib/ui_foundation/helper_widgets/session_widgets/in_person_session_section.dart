import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/session.dart';
import 'package:social_learning/state/available_session_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/custom_card.dart';
import 'package:social_learning/ui_foundation/session_student_page.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

class InPersonSessionSection extends StatelessWidget {
  const InPersonSessionSection({super.key});

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
            '• ${session.name} by ${session.organizerName} with ${session.participantCount} participants';
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
