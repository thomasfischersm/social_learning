import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Helps subscribe to a collection in the Firestore.
class FirestoreListSubscription<T> {
  final String _collectionName;
  final T Function(QueryDocumentSnapshot<Map<String, dynamic>> e)
      _convertSnapshot;
  final Function() _notifyChange;
  List<T> _items = [];

  bool _isInitialized = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _streamSubscription;

  get isInitialized => _isInitialized;

  get items => _items;

  FirestoreListSubscription(
      this._collectionName, this._convertSnapshot, this._notifyChange);

  resubscribe(
      Query<Map<String, dynamic>> Function(
              CollectionReference<Map<String, dynamic>> collectionReference)
          whereFunction) {
    _streamSubscription?.cancel();

    _streamSubscription =
        whereFunction(FirebaseFirestore.instance.collection(_collectionName))
            .snapshots(includeMetadataChanges: true)
            .listen((QuerySnapshot<Map<String, dynamic>> querySnapshot) {
      print(
          'FireStoreListSubscription got ${querySnapshot.docs.length} $_collectionName');
      _items = querySnapshot.docs
          .map((QueryDocumentSnapshot<Map<String, dynamic>> snapshot) =>
              _convertSnapshot(snapshot))
          .toList();

      _isInitialized = true;

      postProcess(_items);

      _notifyChange();
    });
  }

  cancel() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _items = [];
    _notifyChange();
  }

  postProcess(List<T> items) {}
}
