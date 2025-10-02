// test/fast_session_pairing_algorithm_smoke_test.dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_learning/data/firestore_service.dart';
import 'package:social_learning/session_pairing/fast/testing/fast_session_pairing_algorithm_test.dart';

late FakeFirebaseFirestore _fake;

void main() {
  setUp(() {
    _fake = FakeFirebaseFirestore();
    FirestoreService.instance = _fake;
  });

  test('Fast session pairing scenarios', () {
    FastSessionPairingAlgorithmTest().testAll();
  });
}
