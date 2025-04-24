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
import 'package:social_learning/ui_foundation/cms_detail_page.dart';
import 'package:social_learning/ui_foundation/cms_home_page.dart';
import 'package:social_learning/ui_foundation/cms_lesson_page.dart';
import 'package:social_learning/ui_foundation/cms_syllabus_page.dart';
import 'package:social_learning/ui_foundation/code_of_conduct_page.dart';
import 'package:social_learning/ui_foundation/course_create_page.dart';
import 'package:social_learning/ui_foundation/home_page.dart';
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
import 'package:social_learning/ui_foundation/session_home_page.dart';
import 'package:social_learning/ui_foundation/session_host_page.dart';
import 'package:social_learning/ui_foundation/session_student_page.dart';
import 'package:social_learning/ui_foundation/sign_in_page.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';
import 'ui_foundation/bottom_bar.dart';
import 'ui_foundation/profile_page.dart';
import 'ui_foundation/sign_out_page.dart';

// good sign in code lab
// https://firebase.google.com/codelabs/firebase-get-to-know-flutter#4

void main() async {
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

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => applicationState),
      ChangeNotifierProvider(create: (context) => libraryState),
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
        '/instructor_dashboard': (context) =>
            const InstructorDashboardPage(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Consumer<ApplicationState>(
                builder: (context, applicationState, child) {
              return Text('defunc',
                  style: Theme.of(context).textTheme.displayMedium);
            }),
            Consumer<ApplicationState>(
                builder: (context, applicationState, child) {
              return TextButton(
                  onPressed: () {
                    if (applicationState.isLoggedIn) {
                      Navigator.pushNamed(context, '/sign-out');
                    } else {
                      Navigator.pushNamed(context, '/sign-in');
                    }
                  },
                  child: Text(
                      applicationState.isLoggedIn ? 'sign out' : 'sign in'));
            }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // T
      bottomNavigationBar:
          const BottomBar(), // his trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
