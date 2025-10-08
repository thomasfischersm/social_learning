import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:social_learning/state/firestore_subscription/firestore_list_subscription.dart';

class FirestoreListInClausSubscription<Primary, Secondary> {
  late final FirestoreListSubscription<Primary> _primarySubscription;
  final List<FirestoreListSubscription<Secondary>> _secondarySubscription = [];

  final String _secondaryCollectionName;
  final Query<Map<String, dynamic>> Function(CollectionReference<Map<String, dynamic>> collectionReference, List<Primary> primaryBatch) _secondaryQueryBuilder;
  final Secondary Function(QueryDocumentSnapshot<Map<String, dynamic>> e) _secondaryConvertSnapshot;

  final Function() _notifyChange;
  final int _batchSize;
  final int _maxSize;

  List<Primary> get primaryItems => _primarySubscription.items;

  List<Secondary> get secondaryItems =>
      _secondarySubscription.expand((e) => e.items).toList();

  FirestoreListInClausSubscription(
      String primaryCollectionName,
      Primary Function(QueryDocumentSnapshot<Map<String, dynamic>> e) primaryConvertSnapshot,
      this._secondaryCollectionName,
      this._secondaryQueryBuilder,
      this._secondaryConvertSnapshot,
      this._notifyChange,
      {int batchSize = 30, int maxSize = 5 * 30}) : _batchSize = batchSize, _maxSize = maxSize {

    _primarySubscription = FirestoreListSubscription(
      primaryCollectionName,
      primaryConvertSnapshot,
      _notifyChangePrimary,
    );
  }

  resubscribe(
      Query<Map<String, dynamic>> Function(
          CollectionReference<Map<String, dynamic>> collectionReference)
      whereFunction) async {

    await cancel(notify : false);

    _primarySubscription.resubscribe((collectionReference) =>
        whereFunction(collectionReference).limit(_maxSize));
  }

  cancel({bool notify = true}) async {
    await _primarySubscription.cancel();

    await _cancelSecondarySubscriptions();

    if (notify) {
      _notifyChange();
    }
  }

  _cancelSecondarySubscriptions() async {
    Iterable<Future<dynamic>> futures = _secondarySubscription.map((e) => e.cancel());
    await Future.wait(futures);
    _secondarySubscription.clear();
  }

  _notifyChangePrimary() async {
    List<Primary> primaryItems = _primarySubscription.items;

    await _cancelSecondarySubscriptions();

    for (int i = 0; i < primaryItems.length; i += _batchSize) {
      int end = (i + _batchSize < primaryItems.length) ? i + _batchSize : primaryItems.length;
      List<Primary> batch = primaryItems.sublist(i, end);

      var secondarySubscription = FirestoreListSubscription(
        _secondaryCollectionName,
        _secondaryConvertSnapshot,
        _notifyChange,
      );

      secondarySubscription.resubscribe((collectionReference) =>
          _secondaryQueryBuilder(collectionReference, batch));

      _secondarySubscription.add(secondarySubscription);
    }
  }
}
