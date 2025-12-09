import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
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
    final activeCount = sessionParticipants.where((p) => p.isActive).length;
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
      String? rawUserId = UserFunctions.extractNumberId(participantId);
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

    final matching = sessionParticipants
        .where((p) => p.participantUid == currentUser.uid)
        .toList();
    print(
        'Found ${matching.length} matching participants for ${currentUser.uid}');

    if (matching.isEmpty) {
      if (!_isJoinPending) {
        _isJoinPending = true;
        print('Student added itself as a participant (pending join)');
        SessionParticipantFunctions.createParticipant(
          sessionId: session.id!,
          userId: currentUser.id,
          userUid: currentUser.uid,
          courseId: session.courseId.id,
          isInstructor: currentUser.isAdmin,
        ).then((documentReference) {
          print(
              'Participant document created for ${currentUser.uid}: ${documentReference.id}');
        }).catchError((error, stackTrace) {
          print(
              'Failed to create participant document for ${currentUser.uid}: $error');
        }).whenComplete(() {
          _isJoinPending = false;
          print('Join attempt completed for ${currentUser.uid}');
        });
      } else {
        print('Join already pending for ${currentUser.uid}, skipping.');
      }
      return;
    }

    if (matching.length > 1) {
      print(
          'Warning: multiple participant records found for user ${currentUser.uid}');
    }

    if (matching.any((p) => p.isActive)) {
      return;
    }

    final existing = matching.first;
    print('Reactivating existing participant document: ${existing.id}');
    SessionParticipantFunctions.updateIsActive(existing.id!, true);
  }

  SessionParticipant? getParticipantByParticipantId(String participantId) {
    print('getParticipantByParticipantId for $participantId to look through '
        '${items.map((participant) => participant.id)}');
    return items
        .firstWhereOrNull((participant) => participant.id == participantId);
  }

  SessionParticipant? getParticipantByUserId(String userId) {
    print('getParticipantByUserId for $userId to look through '
        '${items.map((participant) => participant.participantId.id)}');
    print('Participant.id = ${items.map((participant) => participant.id)}');
    print('user.uid = ${items.map((participant) => participant.participantUid)}');
    return items.firstWhereOrNull(
        (participant) => participant.participantId.id == userId);
  }
}
