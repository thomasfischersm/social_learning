import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/data_helpers/user_functions.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SignInScreen(
      providers: [
        EmailAuthProvider(),
      ],
      actions: [
        AuthStateChangeAction((context, state) async {
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

            ApplicationState applicationState =
                Provider.of<ApplicationState>(context, listen: false);
            LibraryState libraryState =
                Provider.of<LibraryState>(context, listen: false);
            var currentUser = await applicationState.currentUserBlocking;
            await libraryState.initialize();
            if (currentUser?.currentCourseId != null) {
              if (libraryState.selectedCourse != null) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                    NavigationEnum.courseHome.route,
                    (Route<dynamic> route) => false);
              } else {
                Navigator.of(context).pushNamedAndRemoveUntil(
                    NavigationEnum.home.route,
                    (Route<dynamic> route) => false);
              }
            } else {
              Navigator.of(context).pushNamedAndRemoveUntil(
                  NavigationEnum.home.route, (Route<dynamic> route) => false);
            }
          }
        })
      ],
    );
  }
}
