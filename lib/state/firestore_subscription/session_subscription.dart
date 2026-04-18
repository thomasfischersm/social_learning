import 'package:social_learning/data/session.dart';
import 'package:social_learning/state/firestore_subscription/firestore_document_subscription.dart';
import 'package:social_learning/util/print_util.dart';

class SessionSubscription extends FirestoreDocumentSubscription<Session> {
  SessionSubscription(Function() notifyChange)
      : super((snapshot) {
          dprint('got a new session ${Session.fromSnapshot(snapshot).participantCount}');
          return Session.fromSnapshot(snapshot);
        }, notifyChange);
}
