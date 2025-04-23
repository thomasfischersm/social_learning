import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

class AuthGuard extends StatefulWidget {
  final Widget child;
  const AuthGuard({super.key, required this.child});

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