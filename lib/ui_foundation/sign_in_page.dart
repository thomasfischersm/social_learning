
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/cupertino.dart';

class SignInPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SignInScreen(
      providers: [
        EmailAuthProvider(),
      ],
      actions: [
        AuthStateChangeAction((context, state) {
          var user;
          if (state is SignedIn) {
            user = state.user;
          } else if (state is UserCreated) {
            user = state.credential.user;
          }
          if (user != null) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        })
      ],
    );
  }
}
