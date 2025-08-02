import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

/// This is an invisible widget for the landing page. It checks if the user
/// is still signed in and then re-directs either to the home page or the
/// course home page for the selected course.
class AutoSignInWidget extends StatefulWidget {
  const AutoSignInWidget({super.key});

  @override
  AutoSignInWidgetState createState() => AutoSignInWidgetState();
}

class AutoSignInWidgetState extends State<AutoSignInWidget> {
  bool _isRedirecting = false;

  @override
  Widget build(BuildContext context) {
    return Consumer2<ApplicationState, LibraryState>(
        builder: (context, applicationState, libraryState, child) {
      maybeRedirect(applicationState, libraryState);
      return SizedBox.shrink();
    });
  }

  void maybeRedirect(
      ApplicationState applicationState, LibraryState libraryState) async {
    if (_isRedirecting) {
      return;
    }

    // This triggers the sign-in process. A null could mean that the user
    // couldn't be signed in or that the sign in is still in progress.
    var currentUser = applicationState.currentUser;
    if (currentUser == null) {
      return;
    }

    if (currentUser.currentCourseId == null) {
      _isRedirecting = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          Navigator.of(context).pushReplacementNamed(NavigationEnum.home.route);
        }
      });
      return;
    }

    await libraryState.initialized;

    if (libraryState.selectedCourse != null) {
      _isRedirecting = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          print('Going from the landing page to the course home page.');
          Navigator.of(context)
              .pushReplacementNamed(NavigationEnum.courseHome.route);
        }
      });
      return;
    }

    _isRedirecting = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed(NavigationEnum.home.route);
      }
    });
  }
}
