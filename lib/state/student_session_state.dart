import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:social_learning/data/session.dart';

class StudentSessionState extends ChangeNotifier {
  Session? _currentSession;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _sessionsSubscription;

  get currentSession => _currentSession;

  void attemptToJoin(String sessionId) {
    var oldSubscription = _sessionsSubscription;
    if (oldSubscription != null) {
      oldSubscription.cancel();
      _sessionsSubscription = null;
    }

    _sessionsSubscription = FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .snapshots()
        .listen((snapshot) {
      print('Got new session for student: ${snapshot.data()}');
      _currentSession = Session.fromSnapshot(snapshot);
      notifyListeners();
    });

    // TODO: Check if organizer and re-direct.
    // TODO: Add self as participant if needed.
    // TODO: Subscribe to participants.
  }
}
