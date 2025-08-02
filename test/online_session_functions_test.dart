import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_learning/data/data_helpers/online_session_functions.dart';
import 'package:social_learning/data/firestore_service.dart';
import 'package:social_learning/data/online_session.dart';

void main() {
  late FakeFirebaseFirestore fake;

  setUp(() {
    fake = FakeFirebaseFirestore();
    FirestoreService.instance = fake;
  });

  tearDown(() {
    FirestoreService.instance = null;
  });

  test('createOnlineSession then load', () async {
    final courseRef = fake.collection('courses').doc('c1');
    await courseRef.set({'title': 't'});
    final session = OnlineSession(
      courseId: courseRef,
      learnerUid: 'l',
      mentorUid: 'm',
      isMentorInitiated: false,
      status: OnlineSessionStatus.waiting,
    );
    final ref = await OnlineSessionFunctions.createOnlineSession(session);
    final loaded = await OnlineSessionFunctions.getOnlineSession(ref.id);
    expect(loaded.mentorUid, 'm');
  });
}
