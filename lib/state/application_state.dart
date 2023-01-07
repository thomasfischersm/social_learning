import 'dart:io';

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

  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;

  bool _isCurrentUserInitialized = false;
  User? _currentUser;
  User? get currentUser {
    if (_isLoggedIn && !_isCurrentUserInitialized) {
      var start = DateTime.now().millisecondsSinceEpoch;
      _isCurrentUserInitialized = true;
      () async {
        _currentUser = await UserFunctions.getCurrentUser();

        notifyListeners();
        var end = DateTime.now().millisecondsSinceEpoch;
        // await Future.delayed(Duration(seconds: 5));
      }();
    }
    return _currentUser;
  }

  Future<void> init() async {
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    FirebaseUIAuth.configureProviders([
      EmailAuthProvider(),
    ]);

    auth.FirebaseAuth.instance.idTokenChanges().listen((auth.User? user) {
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
}
