import 'package:social_learning/data/session.dart';
import 'package:social_learning/state/firestore_subscription/firestore_document_subscription.dart';

class SessionSubscription extends FirestoreDocumentSubscription<Session> {
  SessionSubscription(Function() notifyChange)
      : super((snapshot) {
          print('got a new session ${Session.fromSnapshot(snapshot).participantCount}');
          return Session.fromSnapshot(snapshot);
        }, notifyChange);
}
