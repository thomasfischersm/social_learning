import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class AuthGuard extends StatefulWidget {
  final Widget child;
  const AuthGuard({Key? key, required this.child}) : super(key: key);

  @override
  AuthGuardState createState() => AuthGuardState();
}

class AuthGuardState extends State<AuthGuard> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isLoggedIn()) {
      // Redirect after the current frame to avoid build issues.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        NavigationEnum.signIn.navigateClean(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoggedIn() ? widget.child : SizedBox();
  }

  bool _isLoggedIn() {
    ApplicationState applicationState = Provider.of<ApplicationState>(context);
    return applicationState.isLoggedIn;
  }
}