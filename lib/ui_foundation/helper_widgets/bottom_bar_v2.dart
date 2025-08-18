import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/online_session_state.dart';
import 'package:social_learning/state/organizer_session_state.dart';
import 'package:social_learning/state/student_session_state.dart';
import 'package:social_learning/ui_foundation/ui_constants/home_selector.dart';
import 'package:social_learning/ui_foundation/ui_constants/navigation_enum.dart';

class BottomBarV2 {
  static Widget build(BuildContext context) {
    return Consumer4<ApplicationState, LibraryState, StudentSessionState,
            OrganizerSessionState>(
        builder: (context, applicationState, libraryState, studentSessionState,
            organizerSessionState, child) {
      bool isLessonsVisible =
          libraryState.isCourseSelected && applicationState.isLoggedIn;
      bool isManageVisible = _isCourseAdmin(applicationState, libraryState);
      bool isSessionsVisible = applicationState.isLoggedIn &&
          (libraryState.isCourseSelected ||
              studentSessionState.isInitialized ||
              organizerSessionState.isInitialized);
      bool isProfileVisible = applicationState.isLoggedIn;

      var currentIndex = _determineCurrentIndex(
          context,
          applicationState,
          libraryState,
          studentSessionState,
          organizerSessionState,
          isLessonsVisible,
          isManageVisible,
          isSessionsVisible,
          isProfileVisible);

      return BottomNavigationBar(
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          if (isLessonsVisible)
            const BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_rounded),
              label: 'Lessons',
            ),
          if (isManageVisible)
            const BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Manage',
            ),
          if (isSessionsVisible)
            const BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Sessions',
            ),
          if (isProfileVisible)
            const BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
        ],
        currentIndex: currentIndex == -1 ? 0 : currentIndex,
        onTap: (index) => _handleTap(
            index,
            context,
            applicationState,
            libraryState,
            studentSessionState,
            organizerSessionState,
            isLessonsVisible,
            isManageVisible,
            isSessionsVisible,
            isProfileVisible),
        selectedItemColor: currentIndex == -1
            ? Theme.of(context).hintColor
            : Theme.of(context).primaryColor,
        unselectedItemColor: Theme.of(context).hintColor,
      );
    });
  }

  static NavigationEnum _getSessionNavigationTarget(
      BuildContext context,
      ApplicationState applicationState,
      LibraryState libraryState,
      StudentSessionState studentSessionState,
      OrganizerSessionState organizerSessionState) {
    print(
        'bottom bar session button: host session ${organizerSessionState.isInitialized}, student session ${studentSessionState.isInitialized}, course selected ${libraryState.isCourseSelected}, logged in ${applicationState.isLoggedIn}');

    OnlineSessionState onlineSessionState =
        Provider.of<OnlineSessionState>(context, listen: false);
    print(
        'online session state: waiting session ${onlineSessionState.waitingSession}, active session ${onlineSessionState.activeSession}');

    if (organizerSessionState.currentSession != null) {
      return NavigationEnum.sessionHost;
    } else if (studentSessionState.currentSession != null) {
      return NavigationEnum.sessionStudent;
    } else if (onlineSessionState.isInitialized &&
        onlineSessionState.waitingSession != null) {
      return NavigationEnum.onlineSessionWaitingRoom;
    } else if (onlineSessionState.isInitialized &&
        onlineSessionState.activeSession != null) {
      return NavigationEnum.onlineSessionActive;
    } else if (onlineSessionState.isInitialized &&
        onlineSessionState.pendingReview != null) {
      return NavigationEnum.onlineSessionReview;
    } else if (libraryState.isCourseSelected && applicationState.isLoggedIn) {
      return NavigationEnum.sessionHome;
    } else {
      return libraryState.isCourseSelected
          ? NavigationEnum.courseHome
          : NavigationEnum.home;
    }
  }

  static int _determineCurrentIndex(
      BuildContext context,
      ApplicationState applicationState,
      LibraryState libraryState,
      StudentSessionState studentSessionState,
      OrganizerSessionState organizerSessionState,
      bool isLessonsVisible,
      bool isManageVisible,
      bool isSessionsVisible,
      bool isProfileVisible) {
    String? currentRoute = ModalRoute.of(context)?.settings.name;

    if (currentRoute == null) {
      // Use double quotes to avoid escaping the apostrophe in "Couldn't".
      print("Couldn't determine the current route.");
      return -1;
    }

    if ({
      NavigationEnum.home.route,
      NavigationEnum.courseHome.route,
      NavigationEnum.instructorDashBoard.route,
    }.contains(currentRoute)) {
      return 0;
    } else if (isLessonsVisible &&
        {
          NavigationEnum.levelList.route,
          NavigationEnum.levelDetail.route,
          NavigationEnum.lessonDetail.route
        }.contains(currentRoute)) {
      return 1;
    } else if (isManageVisible &&
        {
          NavigationEnum.cmsSyllabus.route,
          NavigationEnum.cmsLesson.route,
          NavigationEnum.instructorClipboard.route,
          NavigationEnum.courseGeneration.route,
          NavigationEnum.courseGenerationReview.route,
          NavigationEnum.courseDesignerIntro.route,
          NavigationEnum.courseDesignerProfile.route,
          NavigationEnum.courseDesignerInventory.route,
          NavigationEnum.courseDesignerPrerequisites.route,
          NavigationEnum.courseDesignerScope.route,
          NavigationEnum.courseDesignerSkillRubric.route,
          NavigationEnum.courseDesignerLearningObjectives.route,
          NavigationEnum.courseDesignerSessionPlan.route,
        }.contains(currentRoute)) {
      return isLessonsVisible ? 2 : 1;
    } else if (isSessionsVisible &&
        {
          NavigationEnum.sessionHome.route,
          NavigationEnum.sessionCreate.route,
          NavigationEnum.sessionCreateWarning.route,
          NavigationEnum.sessionHost.route,
          NavigationEnum.sessionStudent.route,
          NavigationEnum.onlineSessionWaitingRoom.route,
          NavigationEnum.onlineSessionActive.route,
          NavigationEnum.codeOfConduct.route,
          NavigationEnum.onlineSessionReview.route,
        }.contains(currentRoute)) {
      return 1 + (isLessonsVisible ? 1 : 0) + (isManageVisible ? 1 : 0);
    } else if (isProfileVisible &&
        {NavigationEnum.profile.route}.contains(currentRoute)) {
      return 1 +
          (isLessonsVisible ? 1 : 0) +
          (isManageVisible ? 1 : 0) +
          (isSessionsVisible ? 1 : 0);
    } else {
      print('Unknown route: ${currentRoute}');
      return -1;
    }
  }

  static bool _isCourseAdmin(
      ApplicationState applicationState, LibraryState libraryState) {
    print('isCourseAdmin: ${applicationState.currentUser?.displayName}');
    // Must be logged in.
    if (applicationState.currentUser == null) {
      return false;
    }

    // Must have a course selected.
    if (!libraryState.isCourseSelected) {
      return false;
    }

    // Admins can edit all courses.
    if (applicationState.currentUser?.isAdmin == true) {
      return true;
    }

    print(
        'isCourseAdmin: ${libraryState.selectedCourse?.creatorId} == ${applicationState.currentUser?.uid}');
    return libraryState.selectedCourse?.creatorId ==
        applicationState.currentUser?.uid;
  }

  static _handleTap(
      int index,
      BuildContext context,
      ApplicationState applicationState,
      LibraryState libraryState,
      StudentSessionState studentSessionState,
      OrganizerSessionState organizerSessionState,
      bool isLessonsVisible,
      bool isManageVisible,
      bool isSessionsVisible,
      bool isProfileVisible) {
    int originalIndex = index;

    // Home
    if (index == 0) {
      HomeSelector.navigateCleanDelayed(context);
      return;
    } else {
      index--;
    }

    // Curriculum
    if (isLessonsVisible) {
      if (index == 0) {
        print('Navigating from the bottom bar to the level list page.');
        NavigationEnum.levelList.navigateClean(context);
        return;
      } else {
        index--;
      }
    }

    // CMS
    if (isManageVisible) {
      if (index == 0) {
        NavigationEnum.cmsSyllabus.navigateClean(context);
        return;
      } else {
        index--;
      }
    }

    // Sessions
    if (isSessionsVisible) {
      if (index == 0) {
        _getSessionNavigationTarget(context, applicationState, libraryState,
                studentSessionState, organizerSessionState)
            .navigateClean(context);
        return;
      } else {
        index--;
      }
    }

    // Profile
    if (isProfileVisible) {
      if (index == 0) {
        NavigationEnum.profile.navigateClean(context);
        return;
      } else {
        index--;
      }
    }

    print('Unknown index: ${originalIndex}');
  }
}
