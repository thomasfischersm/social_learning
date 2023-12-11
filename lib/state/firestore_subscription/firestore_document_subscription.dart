import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

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

  FirestoreDocumentSubscription(this._convertSnapshot, this._notifyChange) {}

  resubscribe(String Function() docPath) {
    print('Attempting to subscribe to ${docPath()}');
    _streamSubscription?.cancel();

    _streamSubscription = FirebaseFirestore.instance
        .doc(docPath())
        .snapshots()
        .listen((DocumentSnapshot<Map<String, dynamic>> docSnapshot) {
      if (!docSnapshot.metadata.hasPendingWrites) {
        _item = _convertSnapshot(docSnapshot);
      }
      ;

      _isInitialized = true;

      _notifyChange();
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
