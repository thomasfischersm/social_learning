
import 'dart:math';

import 'package:social_learning/data/session_pairing.dart';
import 'package:social_learning/state/firestore_subscription/firestore_list_subscription.dart';

class SessionPairingsSubscription extends FirestoreListSubscription<SessionPairing> {
  Map<int, List<SessionPairing>> _roundNumberToSessionPairings = {};

  get roundNumberToSessionPairings => _roundNumberToSessionPairings;

  SessionPairingsSubscription(Function() notifyChange)
      : super(
          'sessionPairings',
          (snapshot) => SessionPairing.fromSnapshot(snapshot),
          notifyChange,
        );

  @override
  postProcess(List<SessionPairing> sessionPairings) {
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
}
