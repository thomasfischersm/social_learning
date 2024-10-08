import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Helps subscribe to a collection in the Firestore.
class FirestoreDocumentSubscription<T> {
  final T Function(DocumentSnapshot<Map<String, dynamic>> e) _convertSnapshot;
  final Function() _notifyChange;
  T? _item;

  bool _isInitialized = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _streamSubscription;

  get isInitialized => _isInitialized;

  get item => _item;

  FirestoreDocumentSubscription(this._convertSnapshot, this._notifyChange);

  resubscribe(String Function() docPath) {
    print('Attempting to subscribe to ${docPath()}');
    _streamSubscription?.cancel();

    _streamSubscription = FirebaseFirestore.instance
        .doc(docPath())
        .snapshots(includeMetadataChanges: true)
        .listen((DocumentSnapshot<Map<String, dynamic>> docSnapshot) {
      print('Got a new snapshot for ${docPath()}');
      if (!docSnapshot.metadata.hasPendingWrites) {
        _item = _convertSnapshot(docSnapshot);
      } else {
        print('Ignoring update to ${docPath()} because it is pending writes.');
      }

      _isInitialized = true;

      _notifyChange();
    }, onError: (error) {
      print('Error subscribing to ${docPath()}: $error');
    });
  }

  cancel() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _item = null;
    _notifyChange();
  }

  loadItemManually(T item) {
    _item = item;
    _isInitialized = true;
    _notifyChange();
  }
}
