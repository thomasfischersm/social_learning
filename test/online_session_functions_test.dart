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

  test('updateHeartbeat updates lastActive timestamp', () async {
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
    final before = await OnlineSessionFunctions.getOnlineSession(ref.id);
    await Future.delayed(const Duration(milliseconds: 10));
    await OnlineSessionFunctions.updateHeartbeat(ref.id);
    final after = await OnlineSessionFunctions.getOnlineSession(ref.id);
    expect(after.lastActive!.millisecondsSinceEpoch,
        greaterThan(before.lastActive!.millisecondsSinceEpoch));
  });

  test('updateSessionWithMatch sets mentor and lesson', () async {
    final courseRef = fake.collection('courses').doc('c1');
    await courseRef.set({'title': 't'});
    final waitingSession = OnlineSession(
      courseId: courseRef,
      learnerUid: 'l',
      mentorUid: null,
      isMentorInitiated: false,
      status: OnlineSessionStatus.waiting,
    );
    final ref = await OnlineSessionFunctions.createOnlineSession(waitingSession);
    final lessonRef = fake.collection('lessons').doc('lesson1');
    await OnlineSessionFunctions.updateSessionWithMatch(
      sessionId: ref.id,
      mentorUid: 'm',
      lessonRef: lessonRef,
    );
    final updated = await OnlineSessionFunctions.getOnlineSession(ref.id);
    expect(updated.status, OnlineSessionStatus.active);
    expect(updated.mentorUid, 'm');
    expect(updated.lessonId, lessonRef);
    expect(updated.pairedAt, isNotNull);
  });

  test('cancelSession sets status to cancelled', () async {
    final courseRef = fake.collection('courses').doc('c1');
    await courseRef.set({'title': 't'});
    final session = OnlineSession(
      courseId: courseRef,
      learnerUid: 'l',
      isMentorInitiated: false,
      status: OnlineSessionStatus.waiting,
    );
    final ref = await OnlineSessionFunctions.createOnlineSession(session);
    await OnlineSessionFunctions.cancelSession(ref.id);
    final loaded = await OnlineSessionFunctions.getOnlineSession(ref.id);
    expect(loaded.status, OnlineSessionStatus.cancelled);
  });

  test('endSession sets status to completed', () async {
    final courseRef = fake.collection('courses').doc('c1');
    await courseRef.set({'title': 't'});
    final session = OnlineSession(
      courseId: courseRef,
      learnerUid: 'l',
      isMentorInitiated: false,
      status: OnlineSessionStatus.waiting,
    );
    final ref = await OnlineSessionFunctions.createOnlineSession(session);
    await OnlineSessionFunctions.endSession(ref.id);
    final loaded = await OnlineSessionFunctions.getOnlineSession(ref.id);
    expect(loaded.status, OnlineSessionStatus.completed);
  });

  test('getWaitingOrActiveSession returns existing session', () async {
    final courseRef = fake.collection('courses').doc('c1');
    await courseRef.set({'title': 't'});
    final session = OnlineSession(
      courseId: courseRef,
      learnerUid: 'l',
      isMentorInitiated: false,
      status: OnlineSessionStatus.waiting,
    );
    final ref = await OnlineSessionFunctions.createOnlineSession(session);
    final found = await OnlineSessionFunctions.getWaitingOrActiveSession('l', 'c1');
    expect(found?.id, ref.id);
  });
}
