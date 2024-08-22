import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/session_participant.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/data/user_functions.dart';
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
    if ((session != null) &&
        (sessionParticipants.length != session?.participantCount)) {
      // Update the session participant count.
      FirebaseFirestore.instance.collection('sessions').doc(session.id).set(
          {'participantCount': sessionParticipants.length},
          SetOptions(merge: true));
      print('_updateParticipantCount(${sessionParticipants.length}');
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
    print('containsSelf: $containsSelf; this.uid: ${currentUser?.uid}');
    if (!containsSelf) {
      // TODO: This seems to create entries too aggressively.
      print('Student added itself as a participant');
      FirebaseFirestore.instance.collection('sessionParticipants').add({
        'sessionId': FirebaseFirestore.instance.doc('/sessions/${session.id}'),
        'participantId':
            FirebaseFirestore.instance.doc('/users/${currentUser?.id}'),
        'participantUid': currentUser?.uid,
        'courseId': FirebaseFirestore.instance.doc('/courses/${session.courseId.id}'),
        'isInstructor': currentUser?.isAdmin,
        'isActive': true,
      });
    }
  }
}
