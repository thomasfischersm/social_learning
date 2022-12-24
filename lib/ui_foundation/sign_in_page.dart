
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';


class SignInPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SignInScreen(
      providers: [
        EmailAuthProvider(),
      ],
      actions: [
        AuthStateChangeAction((context, state) {
          auth.User? user;
          if (state is SignedIn) {
            user = state.user;
          } else if (state is UserCreated) {
            user = state.credential.user;
          }
          if (user != null) {
            if (user.displayName == null) {
              user.updateDisplayName(user.email?.split('@')[0]);
            }
            Navigator.of(context).pushReplacementNamed('/home');
          }
        })
      ],
    );
  }
}
