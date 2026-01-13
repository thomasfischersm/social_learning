import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/state/organizer_session_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/bottom_bar_v2.dart';
import 'package:social_learning/ui_foundation/helper_widgets/dialog_utils.dart';
import 'package:social_learning/ui_foundation/helper_widgets/general/learning_lab_app_bar.dart';
import 'package:social_learning/ui_foundation/helper_widgets/party_pairing/party_pairing_instructor_pairing_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/party_pairing/party_pairing_roster_card.dart';
import 'package:social_learning/ui_foundation/helper_widgets/party_pairing/party_pairing_student_pairings_list.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_text_styles.dart';
import 'package:social_learning/ui_foundation/ui_constants/custom_ui_constants.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

class PartyPairingHostPage extends StatefulWidget {
  const PartyPairingHostPage({super.key});

  @override
  State<PartyPairingHostPage> createState() =>
      _PartyPairingHostPageState();
}

class _PartyPairingHostPageState extends State<PartyPairingHostPage> {
  bool _isPairingPaused = true;

  @override
  Widget build(BuildContext context) {
    OrganizerSessionState organizerSessionState =
        context.watch<OrganizerSessionState>();
    String sessionName = organizerSessionState.currentSession?.name ?? '';

    return Scaffold(
      appBar: const LearningLabAppBar(),
      bottomNavigationBar: BottomBarV2.build(context),
      floatingActionButton: _buildFloatingActionButton(context),
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

  Widget _buildFloatingActionButton(BuildContext context) {
    IconData pairingIcon =
        _isPairingPaused ? Icons.play_arrow : Icons.pause;
    String pairingLabel =
        _isPairingPaused ? 'Start pairing' : 'Pause pairing';

    return SpeedDial(
      icon: Icons.more_vert,
      activeIcon: Icons.close,
      children: [
        SpeedDialChild(
          onTap: _togglePairing,
          child: Icon(pairingIcon, color: Colors.grey),
          label: pairingLabel,
        ),
        SpeedDialChild(
          onTap: () => _endSession(context),
          child: const Icon(Icons.exit_to_app, color: Colors.grey),
          label: 'End session',
        ),
      ],
    );
  }

  void _togglePairing() {
    setState(() {
      _isPairingPaused = !_isPairingPaused;
    });

    // TODO: Start/stop pairing students.
  }

  void _endSession(BuildContext context) {
    DialogUtils.showConfirmationDialog(
        context, 'End Session', 'Are you sure you want to end the session?',
        () {
      OrganizerSessionState organizerSessionState =
          Provider.of<OrganizerSessionState>(context, listen: false);
      organizerSessionState.endSession();

      Navigator.pushNamed(context, NavigationEnum.sessionHome.route);
    });
  }
}
