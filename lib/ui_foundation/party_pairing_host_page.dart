import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/state/organizer_session_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/general/learning_lab_app_bar.dart';
import 'package:social_learning/ui_foundation/helper_widgets/party_pairing/party_pairing_instructor_pairing_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/party_pairing/party_pairing_roster_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/party_pairing/party_pairing_student_pairings_list.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';

class PartyPairingHostPage extends StatelessWidget {
  const PartyPairingHostPage({super.key});

  @override
  Widget build(BuildContext context) {
    OrganizerSessionState organizerSessionState =
        context.watch<OrganizerSessionState>();
    String sessionName = organizerSessionState.currentSession?.name ?? '';

    return Scaffold(
      appBar: const LearningLabAppBar(),
      bottomNavigationBar: BottomBarV2.build(context),
      body: Align(
        alignment: Alignment.topCenter,
        child: CustomUiConstants.framePage(
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomUiConstants.getTextPadding(Text(
                  'Party Pairing: $sessionName',
                  style: CustomTextStyles.headline,
                )),
                const SizedBox(height: 12),
                const PartyPairingRosterCard(),
                const SizedBox(height: 12),
                const PartyPairingInstructorPairingCard(),
                const SizedBox(height: 12),
                const PartyPairingStudentPairingsList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
