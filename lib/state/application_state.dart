import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:provider/provider.dart';
import 'package:social_learning/data/course.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/data/data_helpers/user_functions.dart';
import 'package:social_learning/state/available_session_state.dart';
import 'package:social_learning/state/library_state.dart';
import 'package:social_learning/state/organizer_session_state.dart';
import 'package:social_learning/state/student_session_state.dart';
import 'package:social_learning/state/student_state.dart';

import '../firebase_options.dart';

class ApplicationState extends ChangeNotifier {
  ApplicationState() {
    init();
  }

  String? get userDisplayName =>
      auth.FirebaseAuth.instance.currentUser?.displayName;

  set userDisplayName(String? newDisplayName) {
    auth.FirebaseAuth.instance.currentUser?.updateDisplayName(newDisplayName);

    var uid = auth.FirebaseAuth.instance.currentUser?.uid;
    if (newDisplayName != null && uid != null) {
      UserFunctions.updateDisplayName(uid, newDisplayName);
    }

    notifyListeners();
  }

  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;

  bool _isCurrentUserInitialized = false;
  User? _currentUser;

  User? get currentUser {
    if (_isLoggedIn && !_isCurrentUserInitialized) {
      _isCurrentUserInitialized = true;
      () async {
        _currentUser = await UserFunctions.getCurrentUser();

        // Update the geo location if the user allows it.
        if (_isCurrentUserInitialized) {
          if (_currentUser?.isGeoLocationEnabled ?? false) {
            UserFunctions.updateGeoLocation(this);
          }
        }

        notifyListeners();
      }();
    }
    return _currentUser;
  }

  Future<void> init() async {
    // await Firebase.initializeApp(
    //     options: DefaultFirebaseOptions.currentPlatform);

    FirebaseUIAuth.configureProviders([
      EmailAuthProvider(),
    ]);

    auth.FirebaseAuth.instance.idTokenChanges().listen((auth.User? user) {
      print('FirebaseAuth state changed: user=$user');
      if (user == null) {
        _isLoggedIn = false;
      } else {
        _isLoggedIn = true;
      }

      _isCurrentUserInitialized = false;
      _currentUser = null;

      notifyListeners();
    });
  }

  void invalidateProfilePhoto() {
    _isCurrentUserInitialized = false;
    _currentUser = null;

    notifyListeners();
  }

  enrollInPrivateCourse(
      Course course, ApplicationState applicationState) async {
    var currentUser = applicationState.currentUser!;

    await FirebaseFirestore.instance.doc('/users/${currentUser.id}').update({
      'enrolledCourseIds': FieldValue.arrayUnion([course.docRef])
    });

    _isCurrentUserInitialized = false;
    _currentUser = await UserFunctions.getCurrentUser(); // TODO: Figure out if this is correct.

    notifyListeners();
  }

  void signOut(BuildContext context) {
    print('Start signOut');
    auth.FirebaseAuth.instance.signOut();
    print('FirebaseAuth signOut done');

    _isLoggedIn = false;
    _isCurrentUserInitialized = false;
    _currentUser = null;

    LibraryState libraryState =
        Provider.of<LibraryState>(context, listen: false);
    libraryState.signOut();

    StudentState studentState =
        Provider.of<StudentState>(context, listen: false);
    studentState.signOut();

    AvailableSessionState availableSessionState =
        Provider.of<AvailableSessionState>(context, listen: false);
    availableSessionState.signOut();

    StudentSessionState studentSessionState =
        Provider.of<StudentSessionState>(context, listen: false);
    studentSessionState.signOut();

    OrganizerSessionState organizerSessionState =
        Provider.of<OrganizerSessionState>(context, listen: false);
    organizerSessionState.signOut();
    print('End signOut');
  }

  void setIsProfilePrivate(bool isProfilePrivate, ApplicationState applicationState) {
    FirebaseFirestore.instance.doc('/users/${currentUser?.id}').update({
      'isProfilePrivate': isProfilePrivate,
    });
    currentUser!.isProfilePrivate = isProfilePrivate;

    // Update any owned documents to private.
    _setProgressVideosPrivate(isProfilePrivate);
    // TODO: Comments

    // Hide/show the user in Geo searches.
    User user = applicationState.currentUser!;
    if (isProfilePrivate && user.isGeoLocationEnabled) {
      UserFunctions.removeGeoFromPracticeRecords(user);
    } else if (!isProfilePrivate && user.isGeoLocationEnabled) {
      UserFunctions.updateGeoLocation(applicationState);
    }

    notifyListeners();
  }

  void _setProgressVideosPrivate(bool isProfilePrivate) {
    FirebaseFirestore.instance
        .collection('progressVideos')
        .where('userId', isEqualTo: FirebaseFirestore.instance.doc('/users/${currentUser?.id}'))
        .get()
        .then((snapshot) {
      for (var doc in snapshot.docs) {
        doc.reference.update({
          'isProfilePrivate': isProfilePrivate,
        });
      }
    });
  }
}
