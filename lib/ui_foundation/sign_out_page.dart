import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:provider/provider.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';

import 'ui_constants/navigation_enum.dart';

class SignOutPage extends StatelessWidget {
  const SignOutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text("Successfully signed out!"),
        TextButton(
            onPressed: () {
              ApplicationState applicationState =
                  Provider.of<ApplicationState>(context, listen: false);
              applicationState.signOut(context);
              Navigator.pushNamed(context, NavigationEnum.landing.route);
            },
            child: const Text("Ghost myself"))
      ],
    );
  }
}
