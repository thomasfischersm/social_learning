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
      FirebaseFirestore.instance
          .collection('sessions')
          .doc(session.id)
          .update({'participantCount': sessionParticipants.length});
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
    User? currentUser = _applicationState!.currentUser;
    if (currentUser == null) {
      return;
    }

    // Find existing participant documents for the current user.
    var matchingParticipants = sessionParticipants
        .where((p) => p.participantUid == currentUser.uid)
        .toList();
    print(
        'containsSelf: ${matchingParticipants.isNotEmpty}; this.uid: ${currentUser.uid}');

    if (matchingParticipants.isEmpty) {
      // No existing participant document; create one.
      print('Student added itself as a participant');
      SessionParticipantFunctions.createSessionParticipant(
        sessionId: session.id,
        userId: currentUser.id,
        participantUid: currentUser.uid,
        courseId: session.courseId.id,
        isInstructor: currentUser.isAdmin,
      );
      return;
    }

    // If an inactive document exists, reactivate the most recent one.
    var activeDocs =
        matchingParticipants.where((p) => p.isActive).toList();
    if (activeDocs.isNotEmpty) {
      return;
    }

    matchingParticipants.sort((a, b) => a.id!.compareTo(b.id!));
    var docToActivate = matchingParticipants.last;
    print(
        'Reactivating existing session participant for ${currentUser.uid} (${docToActivate.id})');

    SessionParticipantFunctions.updateSessionParticipant(
        docToActivate.id!, {'isActive': true});

    // Ensure any other matching documents remain inactive.
    for (var participant in matchingParticipants) {
      if (participant.id != docToActivate.id && participant.isActive) {
        SessionParticipantFunctions.updateSessionParticipant(
            participant.id!, {'isActive': false});
      }
    }
  }
}
