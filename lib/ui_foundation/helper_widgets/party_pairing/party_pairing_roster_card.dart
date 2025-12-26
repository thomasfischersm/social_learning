import 'package:flutter/material.dart';
import 'package:social_learning/ui_foundation/helper_widgets/custom_card.dart';

class PartyPairingRosterCard extends StatelessWidget {
  const PartyPairingRosterCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomCard(
      title: 'Student Roster',
      child: SizedBox.shrink(),
    );
  }
}
