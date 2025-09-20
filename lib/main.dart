import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/globals.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/available_session_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/online_session_state.dart';
import 'package:social_learning/state/organizer_session_state.dart';
import 'package:social_learning/state/student_session_state.dart';
import 'package:social_learning/state/student_state.dart';
import 'package:social_learning/state/course_designer_state.dart';
import 'package:social_learning/ui_foundation/cms_detail_page.dart';
import 'package:social_learning/ui_foundation/cms_home_page.dart';
import 'package:social_learning/ui_foundation/cms_lesson_page.dart';
import 'package:social_learning/ui_foundation/cms_syllabus_page.dart';
import 'package:social_learning/ui_foundation/code_of_conduct_page.dart';
import 'package:social_learning/ui_foundation/course_designer_intro_page.dart';
import 'package:social_learning/ui_foundation/course_designer_inventory_page.dart';
import 'package:social_learning/ui_foundation/course_designer_learning_objectives_page.dart';
import 'package:social_learning/ui_foundation/course_designer_skill_rubric_page.dart';
import 'package:social_learning/ui_foundation/course_designer_prerequisites_page.dart';
import 'package:social_learning/ui_foundation/course_designer_profile_page.dart';
import 'package:social_learning/ui_foundation/course_designer_scope_page.dart';
import 'package:social_learning/ui_foundation/course_designer_session_plan_page.dart';
import 'package:social_learning/ui_foundation/course_generation_review_page.dart';
import 'package:social_learning/ui_foundation/course_create_page.dart';
import 'package:social_learning/ui_foundation/course_generation_page.dart';
import 'package:social_learning/ui_foundation/home_page.dart';
import 'package:social_learning/ui_foundation/course_home_page.dart';
import 'package:social_learning/ui_foundation/instructor_dashboard_page.dart';
import 'package:social_learning/ui_foundation/landing_page.dart';
import 'package:social_learning/ui_foundation/lesson_detail_page.dart';
import 'package:social_learning/ui_foundation/level_detail_page.dart';
import 'package:social_learning/ui_foundation/level_list_page.dart';
import 'package:social_learning/ui_foundation/online_session_active_page.dart';
import 'package:social_learning/ui_foundation/online_session_review_page.dart';
import 'package:social_learning/ui_foundation/online_session_waiting_room_page.dart';
import 'package:social_learning/ui_foundation/other_profile_page.dart';
import 'package:social_learning/ui_foundation/profile_comparison_page.dart';
import 'package:social_learning/ui_foundation/session_create_page.dart';
import 'package:social_learning/ui_foundation/session_create_warning_page.dart';
import 'package:social_learning/ui_foundation/cms_start_page.dart';
import 'package:social_learning/ui_foundation/session_home_page.dart';
import 'package:social_learning/ui_foundation/session_host_page.dart';
import 'package:social_learning/ui_foundation/session_student_page.dart';
import 'package:social_learning/ui_foundation/sign_in_page.dart';
import 'package:social_learning/ui_foundation/instructor_clipboard_page.dart';
import 'package:social_learning/ui_foundation/create_skill_assessment_page.dart';
import 'package:social_learning/ui_foundation/view_skill_assessment_page.dart';

import 'firebase_options.dart';
import 'ui_foundation/profile_page.dart';
import 'ui_foundation/sign_out_page.dart';

// good sign in code lab
// https://firebase.google.com/codelabs/firebase-get-to-know-flutter#4

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Test if enabling persistence caching is a good thing.
  FirebaseFirestore.instance.settings =
      const Settings(persistenceEnabled: true);

  // CustomFirebase.init();
  // FirebaseFirestore.instance.settings = const Settings(host: '127.0.0.1:8080', sslEnabled: false, persistenceEnabled: false);

  ApplicationState applicationState = ApplicationState();
  LibraryState libraryState = LibraryState(applicationState);
  CourseDesignerState courseDesignerState = CourseDesignerState(libraryState);

  unawaited(libraryState.initialize());

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => applicationState),
      ChangeNotifierProvider(create: (context) => libraryState),
      ChangeNotifierProvider(create: (context) => courseDesignerState),
      ChangeNotifierProvider(
          create: (context) => StudentState(applicationState, libraryState)),
      ChangeNotifierProvider(
          create: (context) => AvailableSessionState(libraryState)),
      ChangeNotifierProvider(
          create: (context) =>
              OrganizerSessionState(applicationState, libraryState)),
      ChangeNotifierProvider(
          create: (context) =>
              StudentSessionState(applicationState, libraryState)),
      ChangeNotifierProvider(
          create: (context) =>
              OnlineSessionState(applicationState, libraryState)),
    ],
    builder: ((context, child) => const SocialLearningApp()),
  ));
}

class DebugObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    print('didPush ${route.settings.name} $route');
    // print(StackTrace.current);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    print('didPop ${route.settings.name}');
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    print('didRemove ${route.settings.name}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    print('didReplace ${newRoute?.settings.name}');
    // print(StackTrace.current);
  }
}

class SocialLearningApp extends StatelessWidget {
  const SocialLearningApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [DebugObserver()],
      title: 'Learning Lab',
      scaffoldMessengerKey: snackbarKey,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Ovo',
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/landing',
      routes: {
        '/landing': (context) => const LandingPage(),
        '/home': (context) => const HomePage(),
        '/course_home': (context) => const CourseHomePage(),
        '/profile': (context) => const ProfilePage(),
        '/other_profile': (context) => const OtherProfilePage(),
        '/profile_comparison': (context) => const ProfileComparisonPage(),
        '/level_list': (context) => const LevelListPage(),
        '/level_detail': (context) => const LevelDetailPage(),
        '/lesson_detail': (context) => const LessonDetailPage(),
        '/sign_in': (context) => const SignInPage(),
        '/sign_out': (context) => const SignOutPage(),
        '/cms_home': (context) => const CmsHomePage(),
        '/cms_detail': (context) => const CmsDetailPage(),
        '/cms_syllabus': (context) => const CmsSyllabusPage(),
        '/cms_lesson': (context) => const CmsLessonPage(),
        '/cms_start': (context) => const CmsStartPage(),
        '/session_home': (context) => const SessionHomePage(),
        '/session_create_warning': (context) =>
            const SessionCreateWarningPage(),
        '/session_create': (context) => const SessionCreatePage(),
        '/session_host': (context) => const SessionHostPage(),
        '/session_student': (context) => const SessionStudentPage(),
        '/online_session_waiting_room': (context) =>
            const OnlineSessionWaitingRoomPage(),
        '/online_session_active': (context) => const OnlineSessionActivePage(),
        '/online_session_review': (context) => const OnlineSessionReviewPage(),
        '/create_course': (context) => const CourseCreatePage(),
        '/code_of_conduct': (context) => const CodeOfConductPage(),
        '/instructor_dashboard': (context) => const InstructorDashboardPage(),
        '/instructor_clipboard': (context) => const InstructorClipboardPage(),
        '/create_skill_assessment': (context) =>
            const CreateSkillAssessmentPage(),
        '/view_skill_assessment': (context) => const ViewSkillAssessmentPage(),
        '/course_generation': (context) => const CourseGenerationPage(),
        '/course_generation_review': (context) =>
            const CourseGenerationReviewPage(),
        '/course_designer_profile': (context) => CourseDesignerProfilePage(),
        '/course_designer_intro': (context) => const CourseDesignerIntroPage(),
        '/course_designer_inventory': (context) =>
            const CourseDesignerInventoryPage(),
        '/course_designer_prerequisites': (context) =>
            const CourseDesignerPrerequisitesPage(),
        '/course_designer_scope': (context) => const CourseDesignerScopePage(),
        '/course_designer_skill_rubric': (context) =>
            const CourseDesignerSkillRubricPage(),
        '/course_designer_learning_objectives': (context) =>
            const CourseDesignerLearningObjectivesPage(),
        '/course_designer_session_plan': (context) =>
            const CourseDesignerSessionPlanPage(),
      },
    );
  }
}
