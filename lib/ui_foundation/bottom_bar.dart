import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/organizer_session_state.dart';
import 'package:social_learning/state/student_session_state.dart';

import '../state/application_state.dart';
import 'navigation_enum.dart';

class BottomBar extends StatelessWidget {
  const BottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
        child: Consumer<ApplicationState>(
            builder: (context, applicationState, child) => Row(
                  children: [
                    addIcon(context, Icons.home, NavigationEnum.home, true),
                    Consumer<LibraryState>(
                      builder: (context, libraryState, child) => addIcon(
                          context,
                          Icons.school,
                          NavigationEnum.levelList,
                          libraryState.isCourseSelected &&
                              applicationState.isLoggedIn),
                    ),
                    Consumer<LibraryState>(
                        builder: (context, libraryState, child) =>
                            ((applicationState.currentUser?.isAdmin ?? false) &&
                                    libraryState.isCourseSelected)
                                ? addIcon(context, Icons.menu_book,
                                    NavigationEnum.cmsHome, true)
                                : const Spacer()),
                    Consumer<StudentSessionState>(
                      builder: (context, studentSessionState, child) =>
                          Consumer<OrganizerSessionState>(
                        builder: (context, organizerSessionState, child) =>
                            Consumer<LibraryState>(
                          builder: (context, libraryState, child) => addIcon(
                            context,
                            Icons.groups,
                            _getSessionNavigationTarget(
                                applicationState,
                                libraryState,
                                studentSessionState,
                                organizerSessionState),
                            applicationState.isLoggedIn &&
                                (libraryState.isCourseSelected ||
                                    studentSessionState.isInitialized ||
                                    organizerSessionState.isInitialized),
                          ),
                        ),
                      ),
                    ),
                    addIcon(context, Icons.person, NavigationEnum.profile,
                        applicationState.isLoggedIn),
                  ],
                )));
  }
// TODO: Bottom bar for session doesn't enable/disable properly.
  IconButton addIcon(BuildContext context, IconData? icon,
      NavigationEnum destination, bool isEnabled) {
    var isSelected = ModalRoute.of(context)?.settings.name == destination.route;
    return IconButton(
      icon: Icon(icon),
      isSelected: isSelected,
      color: isSelected
          ? Colors.black
          : isEnabled
              ? Colors.black54
              : Colors.black26,
      onPressed: () {
        if (isEnabled) {
          Navigator.of(context).pushNamed(destination.route);
        }
      },
    );
  }

  NavigationEnum _getSessionNavigationTarget(
      ApplicationState applicationState,
      LibraryState libraryState,
      StudentSessionState studentSessionState,
      OrganizerSessionState organizerSessionState) {
    print(
        'bottom bar session button: host session ${organizerSessionState.isInitialized}, student session ${studentSessionState.isInitialized}, course selected ${libraryState.isCourseSelected}, logged in ${applicationState.isLoggedIn}');

    if (organizerSessionState.currentSession != null) {
      return NavigationEnum.sessionHost;
    } else if (studentSessionState.currentSession != null) {
      return NavigationEnum.sessionStudent;
    } else if (libraryState.isCourseSelected && applicationState.isLoggedIn) {
      return NavigationEnum.sessionHome;
    } else {
      // The user needs to select a course first.
      return NavigationEnum.sessionHome;
    }
  }
}
