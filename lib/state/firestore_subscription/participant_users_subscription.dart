import 'package:social_learning/data/session_participant.dart';
import 'package:social_learning/data/user.dart';
import 'package:social_learning/state/firestore_subscription/firestore_list_subscription.dart';
import 'package:social_learning/state/firestore_subscription/practice_records_subscription.dart';

class ParticipantUsersSubscription extends FirestoreListSubscription<User> {
  final PracticeRecordsSubscription? _practiceRecordSubscription;

  Map<String, User> _uidToUserMap = {};
  Map<String, User> _idToUserMap = {};

  ParticipantUsersSubscription(
      Function() notifyChange, this._practiceRecordSubscription)
      : super('users', (snapshot) => User.fromSnapshot(snapshot), notifyChange);

  User? getUser(SessionParticipant participant) {
    return _uidToUserMap[participant.participantUid];
  }

  User? getUserById(String userId) {
    return _idToUserMap[userId];
  }

  @override
  postProcess(List<User> participantUsers) {
    _uidToUserMap = {for (var user in participantUsers) user.uid: user};
    _idToUserMap = {for (var user in participantUsers) user.id: user};
    print('_idToUserMap: $_idToUserMap');

    _practiceRecordSubscription?.resubscribe((collectionReference) =>
        collectionReference
            .where('isGraduation', isEqualTo: true)
            .where('menteeUid', whereIn: getUserUids()));
  }

  @override
  cancel() async {
    await super.cancel();
    await _practiceRecordSubscription?.cancel();
  }

  List<String> getUserUids() =>
      items.map<String>((User user) => user.uid).toList();
}
