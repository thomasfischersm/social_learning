import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_learning/data/data_helpers/user_functions.dart';
import 'package:social_learning/data/firestore_service.dart';
import 'package:social_learning/data/user.dart';

void main() {
  late FakeFirebaseFirestore fake;

  setUp(() async {
    fake = FakeFirebaseFirestore();
    FirestoreService.instance = fake;
    await fake.collection('users').doc('u1').set({
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

  test('getUserById retrieves the user document', () async {
    final user = await UserFunctions.getUserById('u1');
    expect(user.uid, 'uid1');
    expect(user.displayName, 'Alice');
  });

  test('getUserByUid queries by uid', () async {
    final user = await UserFunctions.getUserByUid('uid1');
    expect(user.id, 'u1');
  });

  test('updateCurrentCourse writes reference', () async {
    final snap = await fake.collection('users').doc('u1').get();
    final user = User.fromSnapshot(snap);

    await UserFunctions.updateCurrentCourse(user, 'course1');

    final updated = await fake.collection('users').doc('u1').get();
    final ref = updated.data()?['currentCourseId'] as DocumentReference;
    expect(ref.path, 'courses/course1');
  });
}
