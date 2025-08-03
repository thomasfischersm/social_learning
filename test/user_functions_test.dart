import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_learning/data/data_helpers/user_functions.dart';
import 'package:social_learning/data/firestore_service.dart';
import 'package:social_learning/data/user.dart';

void main() {
  late FakeFirebaseFirestore fake;

  setUp(() {
    fake = FakeFirebaseFirestore();
    FirestoreService.instance = fake;

    fake.collection('users').doc('u1').set({
      'uid': 'uid1',
      'displayName': 'Alice',
      'sortName': 'alice',
      'profileText': '',
      'isAdmin': false,
      'isProfilePrivate': false,
      'isGeoLocationEnabled': false,
      'created': Timestamp.now(),
      'email': 'alice@example.com',
    });
  });

  tearDown(() {
    FirestoreService.instance = null;
  });

  tearDown(() {
    FirestoreService.instance = null;
  });

  test('getUserById retrieves the user document', () async {
    final user = await UserFunctions.getUserById('u1');
    expect(user.uid, 'uid1');
    expect(user.displayName, 'Alice');
  });

  test('getUserByUid queries by uid', () async {
    final user = await UserFunctions.getUserByUid('uid1');
    expect(user.id, 'u1');
  });

  test('updateCurrentCourse writes reference and updates user object',
      () async {
    final snap = await fake.collection('users').doc('u1').get();
    final user = User.fromSnapshot(snap);

    await UserFunctions.updateCurrentCourse(user, 'course1');

    // In-memory update on the user model.
    expect(user.currentCourseId!.path, 'courses/course1');

    // Firestore document is updated.
    final updated = await fake.collection('users').doc('u1').get();
    final ref = updated.data()?['currentCourseId'] as DocumentReference;
    expect(ref.path, 'courses/course1');
  });

  test('findUsersByPartialDisplayName returns empty list for short query',
      () async {
    final results =
        await UserFunctions.findUsersByPartialDisplayName('Al', 5);
    expect(results, isEmpty);
  });

  test('extractNumberId returns the last path segment or null', () {
    final ref = fake.doc('courses/123');
    expect(UserFunctions.extractNumberId(ref), '123');
    expect(UserFunctions.extractNumberId(null), isNull);
  });
}
