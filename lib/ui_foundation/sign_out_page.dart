import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/state/application_state.dart';

import 'ui_constants/navigation_enum.dart';

class SignOutPage extends StatelessWidget {
  const SignOutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text("Successfully signed out!"),
        TextButton(
            onPressed: () async {
              ApplicationState applicationState =
                  Provider.of<ApplicationState>(context, listen: false);
              Navigator.pushNamedAndRemoveUntil(
                  context,
                  NavigationEnum.landing.route,
                      (Route<dynamic> route) => false);
              await applicationState.signOut(context);
            },
            child: const Text("Ghost myself"))
      ],
    );
  }
}
