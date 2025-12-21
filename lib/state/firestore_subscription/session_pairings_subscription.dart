import 'dart:math';

import 'package:social_learning/data/session_pairing.dart';
import 'package:social_learning/state/firestore_subscription/firestore_list_subscription.dart';

class SessionPairingsSubscription
    extends FirestoreListSubscription<SessionPairing> {
  final Map<int, List<SessionPairing>> _roundNumberToSessionPairings = {};

  Map<int, List<SessionPairing>> get roundNumberToSessionPairings =>
      _roundNumberToSessionPairings;

  SessionPairingsSubscription(Function() notifyChange)
      : super(
          'sessionPairings',
          (snapshot) {
            print('Trying to load session paring: ${snapshot.id}');
            return SessionPairing.fromSnapshot(snapshot);
          },
          notifyChange,
        );

  @override
  postProcess(List<SessionPairing> sessionPairings) {
    _roundNumberToSessionPairings.clear();

    for (SessionPairing pairing in sessionPairings) {
      if (!_roundNumberToSessionPairings.containsKey(pairing.roundNumber)) {
        _roundNumberToSessionPairings[pairing.roundNumber] = [];
      }
      _roundNumberToSessionPairings[pairing.roundNumber]!.add(pairing);
    }
  }

  int getLatestRoundNumber() {
    int latestRoundNumber = -1;

    for (SessionPairing pairing in items) {
      latestRoundNumber = max(latestRoundNumber, pairing.roundNumber);
    }

    return latestRoundNumber;
  }

  List<SessionPairing>? getLastRound() {
    int latestRoundNumber = getLatestRoundNumber();
    return _roundNumberToSessionPairings[latestRoundNumber];
  }
}
