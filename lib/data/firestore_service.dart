import 'package:cloud_firestore/cloud_firestore.dart';

/// Singleton wrapper for [FirebaseFirestore] that allows overriding the
/// instance in tests.
class FirestoreService {
  /// The Firestore instance used by the app. Tests can replace this
  /// with a [FakeFirebaseFirestore].
  static FirebaseFirestore instance = FirebaseFirestore.instance;
}
