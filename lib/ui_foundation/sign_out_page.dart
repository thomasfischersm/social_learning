import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

import 'navigation_enum.dart';

class SignOutPage extends StatelessWidget {
  const SignOutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("Successfully signed out!"),
        TextButton(
            onPressed: () {
              auth.FirebaseAuth.instance.signOut();
              Navigator.pushNamed(context, NavigationEnum.landing_page.route);
            },
            child: const Text("Ghost myself"))
      ],
    );
  }
}
