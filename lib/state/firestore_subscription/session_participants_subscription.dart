import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/session_participant.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/data/data_helpers/user_functions.dart';
import 'package:social_learning/data/data_helpers/session_participant_functions.dart';
import 'package:social_learning/state/application_state.dart';
import 'package:social_learning/state/firestore_subscription/firestore_list_subscription.dart';
import 'package:social_learning/state/firestore_subscription/participant_users_subscription.dart';
import 'package:social_learning/state/firestore_subscription/session_subscription.dart';

class SessionParticipantsSubscription
    extends FirestoreListSubscription<SessionParticipant> {
  final bool _shouldUpdateParticipantCount;
  final bool _shouldAddUserToSession;
  final SessionSubscription _sessionSubscription;
  final ParticipantUsersSubscription _participantUsersSubscription;
  final ApplicationState? _applicationState;
  bool _isJoinPending = false;

  SessionParticipantsSubscription(
      this._shouldUpdateParticipantCount,
      this._shouldAddUserToSession,
      Function() notifyChange,
      this._sessionSubscription,
      this._participantUsersSubscription,
      this._applicationState)
      : super(
          'sessionParticipants',
          (snapshot) => SessionParticipant.fromSnapshot(snapshot),
          notifyChange,
        );

  @override
  postProcess(List<SessionParticipant> sessionParticipants) {
    var session = _sessionSubscription.item;

    if (_shouldUpdateParticipantCount) {
      _updateParticipantCount(session, sessionParticipants);
    }

    if (_shouldAddUserToSession) {
      var currentUid = _applicationState?.currentUser?.uid;
      if (_isJoinPending &&
          currentUid != null &&
          sessionParticipants.any(
              (participant) => participant.participantUid == currentUid)) {
        _isJoinPending = false;
      }

      _addUserToSession(session, sessionParticipants);
    }

    var userIds = getUserIds();
    if (userIds.isNotEmpty) {
      _participantUsersSubscription.resubscribe((collectionReference) =>
          collectionReference.where(FieldPath.documentId, whereIn: userIds));
    } else {
      _participantUsersSubscription.cancel();
    }
  }

  void _updateParticipantCount(
      session, List<SessionParticipant> sessionParticipants) {
    final activeCount =
        sessionParticipants.where((p) => p.isActive).length;
    if ((session != null) && (activeCount != session?.participantCount)) {
      // Update the session participant count.
      FirebaseFirestore.instance
          .collection('sessions')
          .doc(session.id)
          .update({'participantCount': activeCount});
      print('_updateParticipantCount($activeCount)');
    }
  }

  List<String> getUserIds() {
    List<String> userIds = [];
    for (SessionParticipant participant in items) {
      var participantId = participant.participantId;
      var rawUserId = UserFunctions.extractNumberId(participantId);
      if (rawUserId != null) {
        userIds.add(rawUserId);
      }
    }
    return userIds;
  }

  void _addUserToSession(
      session, List<SessionParticipant> sessionParticipants) {
    // Check if self needs to be added.
    User? currentUser = _applicationState!.currentUser;
    var containsSelf = sessionParticipants.any((element) {
      print(
          'Checking if ${element.participantUid} == ${currentUser?.uid} => ${element.participantUid == currentUser?.uid}');
      return element.participantUid == currentUser?.uid;
    });
    print(
        'containsSelf: $containsSelf; this.uid: ${currentUser?.uid}; isJoinPending: $_isJoinPending');
    if (_isJoinPending || containsSelf || currentUser == null) {
      return;
    }

    _isJoinPending = true;
    print('Student added itself as a participant');
    SessionParticipantFunctions.createParticipant(
      sessionId: session.id!,
      userId: currentUser.id,
      userUid: currentUser.uid,
      courseId: session.courseId.id,
      isInstructor: currentUser.isAdmin,
    ).catchError((error) {
      _isJoinPending = false;
      print('Error adding participant: $error');
    });
  }
}
