import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/data/session_participant.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/data/user_functions.dart';
import 'package:social_learning/state/firestore_subscription/firestore_list_subscription.dart';
import 'package:social_learning/state/firestore_subscription/participant_users_subscription.dart';
import 'package:social_learning/state/firestore_subscription/session_subscription.dart';

class SessionParticipantsSubscription
    extends FirestoreListSubscription<SessionParticipant> {
  final SessionSubscription _sessionSubscription;
  final ParticipantUsersSubscription _participantUsersSubscription;

  SessionParticipantsSubscription(
      Function() notifyChange,
      this._sessionSubscription,
      this._participantUsersSubscription)
      : super(
          'sessionParticipants',
          (snapshot) => SessionParticipant.fromSnapshot(snapshot),
          notifyChange,
        );

  @override
  postProcess(List<SessionParticipant> sessionParticipants) {
    var session = _sessionSubscription.item;
    if ((session != null) &&
        (sessionParticipants.length != session?.participantCount)) {
      // Update the session participant count.
      FirebaseFirestore.instance.collection('sessions').doc(session.id).set(
          {'participantCount': sessionParticipants.length},
          SetOptions(merge: true));
    }

    var userIds = getUserIds();
    if (userIds.isNotEmpty) {
      _participantUsersSubscription.resubscribe((collectionReference) =>
          collectionReference.where(FieldPath.documentId, whereIn: userIds));
    } else {
      _participantUsersSubscription.cancel();
    }
  }

  List<String> getUserIds() {
    List<String> userIds = [];
    for (SessionParticipant participant in items) {
      var participantId = participant.participantId;
      if (participantId != null) {
        var rawUserId = UserFunctions.extractNumberId(participantId);
        if (rawUserId != null) {
          userIds.add(rawUserId);
        }
      }
    }
    return userIds;
  }
}
