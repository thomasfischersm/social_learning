import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/data/user_functions.dart';

import '../data/course.dart';
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

  bool _loggedIn = false;

  bool get isLoggedIn => _loggedIn;

  bool _isProfilePhotoUrlInitialized = false;
  String? _profilePhotoUrl;

  String? get profilePhotoUrl {
    print('profilePhotoUrl $_profilePhotoUrl');
    if (!_isProfilePhotoUrlInitialized) {
      _isProfilePhotoUrlInitialized = true;
      () async {
        print('start profile photo URL loading');
        User user = await UserFunctions.getCurrentUser();
        _profilePhotoUrl = user.profilePhotoUrl;

        notifyListeners();
        print('done with profile photo url loading $_profilePhotoUrl');
      }();
    }
    return _profilePhotoUrl;
  }

  Future<void> init() async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    FirebaseUIAuth.configureProviders([
      EmailAuthProvider(),
    ]);

    auth.FirebaseAuth.instance.idTokenChanges().listen((auth.User? user) {
      if (user == null) {
        _loggedIn = false;
      } else {
        _loggedIn = true;
      }

      _isProfilePhotoUrlInitialized = false;
      _profilePhotoUrl = null;

      notifyListeners();
    });
  }

  void invalidateProfilePhoto() {
    _isProfilePhotoUrlInitialized = false;
    notifyListeners();
  }
}
