
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:social_learning/data/data_helpers/user_functions.dart';


class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

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

            if (user != null) {
              UserFunctions.createUser(user.uid, user.displayName, user.email);
            }
          }
          if (user != null) {
            if (user.displayName == null) {
              var defaultDisplayName = user.email?.split('@')[0];
              user.updateDisplayName(defaultDisplayName);

              if (defaultDisplayName != null) {
                UserFunctions.updateDisplayName(user.uid, defaultDisplayName);
              }
            }
            Navigator.of(context).pushReplacementNamed('/home');
          }
        })
      ],
    );
  }
}
