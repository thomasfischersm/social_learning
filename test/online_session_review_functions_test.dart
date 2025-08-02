import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_learning/data/data_helpers/online_session_review_functions.dart';
import 'package:social_learning/data/firestore_service.dart';
import 'package:social_learning/data/online_session.dart';

void main() {
  late FakeFirebaseFirestore fake;

  setUp(() {
    fake = FakeFirebaseFirestore();
    FirestoreService.instance = fake;
  });

  tearDown(() {
    FirestoreService.instance = FirebaseFirestore.instance;
  });

  test('createPendingReviewsForSession creates two reviews', () async {
    final courseRef = fake.collection('courses').doc('c1');
    final lessonRef = fake.collection('lessons').doc('l1');
    await courseRef.set({'title': 't'});
    await lessonRef.set({'name': 'lesson'});
    final session = OnlineSession(
      id: 's1',
      courseId: courseRef,
      learnerUid: 'l',
      mentorUid: 'm',
      isMentorInitiated: false,
      status: OnlineSessionStatus.active,
      lessonId: lessonRef,
    );
    await fake.collection('onlineSessions').doc('s1').set({
      'courseId': courseRef,
      'learnerUid': 'l',
      'mentorUid': 'm',
      'videoCallUrl': null,
      'isMentorInitiated': false,
      'status': OnlineSessionStatus.active.code,
      'created': Timestamp.now(),
      'lastActive': Timestamp.now(),
      'pairedAt': Timestamp.now(),
      'lessonId': lessonRef,
    });
    await OnlineSessionReviewFunctions.createPendingReviewsForSession(session);
    final reviews = await fake.collection('onlineSessionReviews').get();
    expect(reviews.docs.length, 2);
  });
}
