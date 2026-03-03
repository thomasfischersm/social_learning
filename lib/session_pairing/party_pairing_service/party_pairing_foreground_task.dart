import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:social_learning/firebase_options.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/organizer_session_state.dart';

class PartyPairingForegroundTask extends TaskHandler {
  OrganizerSessionState? _organizerSessionState;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseFirestore.instance.settings =
        const Settings(persistenceEnabled: true);

    ApplicationState applicationState = ApplicationState();
    LibraryState libraryState = LibraryState(applicationState);
    await libraryState.initialize();

    OrganizerSessionState organizerSessionState =
        OrganizerSessionState(applicationState, libraryState);

    organizerSessionState.addListener(runIncrementalPairing);
    _organizerSessionState = organizerSessionState;
  }

  void runIncrementalPairing() {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    _organizerSessionState?.removeListener(runIncrementalPairing);
  }

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/');
  }

  @override
  void onNotificationDismissed() {}
}
