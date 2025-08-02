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
    FirestoreService.instance = null;
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

  test('createPendingReviewsForSession does nothing without lesson', () async {
    final courseRef = fake.collection('courses').doc('c2');
    await courseRef.set({'title': 't2'});
    final session = OnlineSession(
      id: 's2',
      courseId: courseRef,
      learnerUid: 'l',
      mentorUid: 'm',
      isMentorInitiated: false,
      status: OnlineSessionStatus.active,
      lessonId: null,
    );
    await fake.collection('onlineSessions').doc('s2').set({
      'courseId': courseRef,
      'learnerUid': 'l',
      'mentorUid': 'm',
      'videoCallUrl': null,
      'isMentorInitiated': false,
      'status': OnlineSessionStatus.active.code,
      'created': Timestamp.now(),
      'lastActive': Timestamp.now(),
      'pairedAt': Timestamp.now(),
      'lessonId': null,
    });

    await OnlineSessionReviewFunctions.createPendingReviewsForSession(session);
    final reviews = await fake.collection('onlineSessionReviews').get();
    expect(reviews.docs.length, 0);
  });

  test('fillOutReview updates review and marks as not pending', () async {
    final courseRef = fake.collection('courses').doc('c3');
    final lessonRef = fake.collection('lessons').doc('l3');
    final sessionRef = fake.collection('onlineSessions').doc('s3');
    await courseRef.set({'title': 't3'});
    await lessonRef.set({'name': 'lesson3'});
    await sessionRef.set({
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

    await fake.collection('onlineSessionReviews').doc('r3').set({
      'sessionId': sessionRef,
      'lessonId': lessonRef,
      'courseId': courseRef,
      'mentorUid': 'm',
      'learnerUid': 'l',
      'reviewerUid': 'm',
      'isMentor': true,
      'partnerRating': 0,
      'lessonRating': 0,
      'publicReview': null,
      'improvementFeedback': null,
      'keepDoingFeedback': null,
      'blockUser': false,
      'reportUser': false,
      'reportDetails': null,
      'isPending': true,
      'created': Timestamp.now(),
    });

    await OnlineSessionReviewFunctions.fillOutReview(
      reviewId: 'r3',
      partnerRating: 5,
      lessonRating: 4,
      publicReview: 'Great',
      improvementFeedback: 'Improve',
      keepDoingFeedback: 'Keep',
      blockUser: true,
      reportUser: true,
      reportDetails: 'details',
    );

    final doc = await fake.collection('onlineSessionReviews').doc('r3').get();
    final data = doc.data()!;
    expect(data['partnerRating'], 5);
    expect(data['lessonRating'], 4);
    expect(data['publicReview'], 'Great');
    expect(data['improvementFeedback'], 'Improve');
    expect(data['keepDoingFeedback'], 'Keep');
    expect(data['blockUser'], true);
    expect(data['reportUser'], true);
    expect(data['reportDetails'], 'details');
    expect(data['isPending'], false);
  });

  test('deleteReview removes the review document', () async {
    final reviewRef = fake.collection('onlineSessionReviews').doc('r4');
    await reviewRef.set({'isPending': true});

    await OnlineSessionReviewFunctions.deleteReview('r4');

    final doc = await reviewRef.get();
    expect(doc.exists, false);
  });
}
