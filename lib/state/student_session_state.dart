import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:social_learning/data/session.dart';
import 'package:social_learning/data/session_participant.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/ui_foundation/navigation_enum.dart';

class StudentSessionState extends ChangeNotifier {
  Session? _currentSession;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _sessionsSubscription;

  get currentSession => _currentSession;

  List<SessionParticipant> _sessionParticipants = List.empty();

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _sessionParticipantsSubscription;

  get sessionParticipants => _sessionParticipants;

  void attemptToJoin(String sessionId, BuildContext context) {
    ApplicationState applicationState =
        Provider.of<ApplicationState>(context, listen: false);

    var oldSessionSubscription = _sessionsSubscription;
    if (oldSessionSubscription != null) {
      oldSessionSubscription.cancel();
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

      // If the user is already the host, re-direct from the student to the
      // host page.
      if (_currentSession?.organizerUid == applicationState.currentUser?.uid) {
        Navigator.pushNamed(context, NavigationEnum.sessionHost.route);
        return;
      }
    });

    var oldSessionParticipantsSubscription = _sessionParticipantsSubscription;
    if (oldSessionParticipantsSubscription != null) {
      oldSessionParticipantsSubscription.cancel();
      _sessionParticipantsSubscription = null;
    }

    String sessionPath = '/sessions/$_currentSession.id';
    _sessionParticipantsSubscription = FirebaseFirestore.instance
        .collection('sessionParticipants')
        .where('sessionId',
            isEqualTo: FirebaseFirestore.instance.doc(sessionPath))
        .snapshots()
        .listen((snapshot) {
      print('Got new session participants for student: ${snapshot.docs.length}');
      _sessionParticipants =
          snapshot.docs.map((e) => SessionParticipant.fromSnapshot(e)).toList();
      notifyListeners();

      // Check if self needs to be added.
      var containsSelf = _sessionParticipants.any((element) {
        print('Checking if ${element.participantUid} == ${applicationState.currentUser?.uid} => ${element.participantUid == applicationState.currentUser?.uid}');
        return element.participantUid == applicationState.currentUser?.uid;
      });
      print('containsSelf: $containsSelf; this.uid: ${applicationState.currentUser?.uid}');
      if (!containsSelf) {
        print('Student added itself as a participant');
        FirebaseFirestore.instance.collection('sessionParticipants').add({
          'sessionId': FirebaseFirestore.instance.doc(sessionPath),
          'participantId': FirebaseFirestore.instance.doc('/users/${applicationState.currentUser?.id}'),
          'participantUid': applicationState.currentUser?.uid,
          'isInstructor': false,
        });
      }
    });

    // TODO: Check if organizer and re-direct.
    // TODO: Add self as participant if needed.
    // TODO: Subscribe to participants.
  }
}
