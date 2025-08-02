import 'package:cloud_firestore/cloud_firestore.dart';

/// Singleton wrapper for [FirebaseFirestore] that allows overriding the
/// instance in tests.
class FirestoreService {
  /// The Firestore instance used by the app. Tests can replace this
  /// with a [FakeFirebaseFirestore]. When `null`, the default
  /// [FirebaseFirestore.instance] will be lazily obtained on first use.
  static FirebaseFirestore? _instance;

  static FirebaseFirestore get instance =>
      _instance ??= FirebaseFirestore.instance;

  static set instance(FirebaseFirestore? firestore) {
    _instance = firestore;
  }
}
