import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/ui_foundation/helper_widgets/user_profile_widgets/radar_widget.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

class RadarCard extends StatelessWidget {
  const RadarCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child:
            Consumer<ApplicationState>(builder: (context, applicationState, _) {
              return InkWell(onTap: () {
                _navigateToSkillAssessment(context);
              },
                  child: Stack(children: [
                    Center(child:RadarWidget(user: applicationState.currentUser!,
                        showLabels: false,
                        size: 100)),
                    const Positioned(
                        bottom: 0,
                        right: 0,
                        child: Icon(Icons.remove_red_eye, color: Colors.grey,))
                  ]));
            }
            )));
  }

  void _navigateToSkillAssessment(BuildContext context) {
    if (context.mounted) {
      NavigationEnum.viewSkillAssessment.navigateClean(context);
    }
  }
}
