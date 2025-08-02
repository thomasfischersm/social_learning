import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

class CreatorGuard extends StatefulWidget {
  final Widget child;
  const CreatorGuard({super.key, required this.child});

  @override
  CreatorGuardState createState() => CreatorGuardState();
}

class CreatorGuardState extends State<CreatorGuard> {
  bool _navigationScheduled = false;

  @override
  Widget build(BuildContext context) {
    // By default, Provider.of will re-invoke build whenever the
    // LibraryState or ApplicationState notify listeners.
    final libraryState      = Provider.of<LibraryState>(context);
    final applicationState  = Provider.of<ApplicationState>(context);
    final course            = libraryState.selectedCourse;
    final user              = applicationState.currentUser;

    // If we know both course and user, enforce the guard:
    if (course != null && user != null) {
      final isCreator = course.creatorId == user.uid || user.isAdmin;
      if (!isCreator) {
        // schedule the one‐time redirect
        if (!_navigationScheduled) {
          _navigationScheduled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (libraryState.isCourseSelected) {
              NavigationEnum.courseHome.navigateCleanDelayed(context);
            } else {
              NavigationEnum.home.navigateCleanDelayed(context);
            }
          });
        }
        return const SizedBox();  // render nothing while redirecting
      }
      // they _are_ creator/admin → show the child
      return widget.child;
    }

    // still loading / not enough data → let them see the child
    return widget.child;
  }
}
