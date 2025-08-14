import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/user.dart';
import '../../state/application_state.dart';
import '../../state/library_state.dart';
import 'navigation_enum.dart';

class HomeSelector {
  static void navigateCleanDelayed(BuildContext context) {
    if (!context.mounted) {
      return;
    }

    LibraryState libraryState =
        Provider.of<LibraryState>(context, listen: false);
    ApplicationState applicationState =
        Provider.of<ApplicationState>(context, listen: false);
    User currentUser = applicationState.currentUser!;

    if (!libraryState.isCourseSelected) {
      NavigationEnum.home.navigateCleanDelayed(context);
    } else if (libraryState.selectedCourse!.creatorId == currentUser.uid ||
        currentUser.isAdmin) {
      NavigationEnum.instructorDashBoard.navigateCleanDelayed(context);
    } else {
      NavigationEnum.courseHome.navigateCleanDelayed(context);
    }
  }
}
