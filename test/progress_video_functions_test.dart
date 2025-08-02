import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_learning/data/data_helpers/progress_video_functions.dart';
import 'package:social_learning/data/data_helpers/reference_helper.dart';
import 'package:social_learning/data/firestore_service.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/progress_video.dart';
import 'package:social_learning/data/user.dart';

void main() {
  late FakeFirebaseFirestore fake;

  setUp(() {
    fake = FakeFirebaseFirestore();
    FirestoreService.instance = fake;
  });

  tearDown(() {
    FirestoreService.instance = null;
  });

  test('isValidYouTubeUrl validates common cases', () {
    expect(
        ProgressVideoFunctions.isValidYouTubeUrl(
            'https://youtu.be/ABCDEFG1234'),
        isTrue);
    expect(
        ProgressVideoFunctions.isValidYouTubeUrl(
            'https://www.youtube.com/watch?v=ABCDEFG1234'),
        isTrue);
    expect(
        ProgressVideoFunctions.isValidYouTubeUrl(
            'https://www.youtube.com/embed/ABCDEFG1234'),
        isTrue);
    expect(ProgressVideoFunctions.isValidYouTubeUrl('https://example.com'),
        isFalse);
    expect(ProgressVideoFunctions.isValidYouTubeUrl('not a url'), isFalse);
  });

  test('extractYouTubeVideoId parses ID from various URL styles', () {
    expect(
        ProgressVideoFunctions.extractYouTubeVideoId(
            'https://youtu.be/ABCDEFG1234'),
        'ABCDEFG1234');
    expect(
        ProgressVideoFunctions.extractYouTubeVideoId(
            'https://www.youtube.com/watch?v=ABCDEFG1234'),
        'ABCDEFG1234');
    expect(
        ProgressVideoFunctions.extractYouTubeVideoId(
            'https://www.youtube.com/embed/ABCDEFG1234'),
        'ABCDEFG1234');
    expect(
        ProgressVideoFunctions.extractYouTubeVideoId(
            'https://www.youtube.com/watch?v=ABCDEFG1234&t=1s'),
        'ABCDEFG1234');
    expect(ProgressVideoFunctions.extractYouTubeVideoId('https://example.com'),
        isNull);
  });

  test('createProgressVideo writes document with expected fields', () async {
    final userRef = fake.collection('users').doc('u1');
    await userRef.set({'uid': 'uid1'});
    final courseRef = fake.collection('courses').doc('c1');
    await courseRef.set({'title': 't'});
    final lessonRef = fake.collection('lessons').doc('l1');
    await lessonRef.set({'courseId': courseRef});

    final lesson = Lesson('l1', courseRef, null, 0, 't', null, '', null, null,
        null, null, null, null, '', null);
    final user = User('u1', 'uid1', '', '', null, '', false, null, null, null,
        false, null, false, null, null, null, null, null,
        Timestamp.fromMillisecondsSinceEpoch(0));

    await ProgressVideoFunctions.createProgressVideo(
        lesson, user, 'https://youtu.be/ABC123DEF45');

    final snap = await fake.collection('progressVideos').get();
    expect(snap.docs.length, 1);
    final data = snap.docs.first.data();
    expect((data['userId'] as DocumentReference).path, userRef.path);
    expect(data['userUid'], 'uid1');
    expect((data['courseId'] as DocumentReference).path, courseRef.path);
    expect((data['lessonId'] as DocumentReference).path, lessonRef.path);
    expect(data['youtubeUrl'], 'https://youtu.be/ABC123DEF45');
    expect(data['youtubeVideoId'], 'ABC123DEF45');
    expect(data['isProfilePrivate'], false);
    expect(data['timestamp'], isNotNull);
  });

  test('convertAsyncSnapshotToSortedProgressVideos returns empty when null',
      () {
    final asyncSnapshot =
        AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>>.withData(
            ConnectionState.done, null);
    final videos = ProgressVideoFunctions
        .convertAsyncSnapshotToSortedProgressVideos(asyncSnapshot);
    expect(videos, isEmpty);
  });

  test('convertSnapshotToSortedProgressVideos sorts by timestamp', () async {
    final userRef = docRef('users', 'u1');
    final courseRef = docRef('courses', 'c1');
    final lessonRef = docRef('lessons', 'l1');

    await fake.collection('progressVideos').doc('v1').set({
      'userId': userRef,
      'userUid': 'uid1',
      'courseId': courseRef,
      'lessonId': lessonRef,
      'youtubeUrl': 'u1',
      'youtubeVideoId': 'id1',
      'isProfilePrivate': false,
      'timestamp': Timestamp.fromMillisecondsSinceEpoch(10)
    });
    await fake.collection('progressVideos').doc('v2').set({
      'userId': userRef,
      'userUid': 'uid1',
      'courseId': courseRef,
      'lessonId': lessonRef,
      'youtubeUrl': 'u2',
      'youtubeVideoId': 'id2',
      'isProfilePrivate': false,
      'timestamp': Timestamp.fromMillisecondsSinceEpoch(20)
    });
    await fake.collection('progressVideos').doc('v3').set({
      'userId': userRef,
      'userUid': 'uid1',
      'courseId': courseRef,
      'lessonId': lessonRef,
      'youtubeUrl': 'u3',
      'youtubeVideoId': 'id3',
      'isProfilePrivate': false,
      'timestamp': Timestamp.fromMillisecondsSinceEpoch(30)
    });

    final snapshot = await fake.collection('progressVideos').get();
    final videos =
        ProgressVideoFunctions.convertSnapshotToSortedProgressVideos(snapshot);
    expect(videos.map((e) => e.id).toList(), ['v3', 'v2', 'v1']);
  });

  test('streamCourseVideos excludes private videos and respects limit', () async {
    final courseRef = docRef('courses', 'c1');
    final lessonRef = docRef('lessons', 'l1');
    final userRef = docRef('users', 'u1');

    await fake.collection('progressVideos').doc('v1').set({
      'userId': userRef,
      'userUid': 'uid1',
      'courseId': courseRef,
      'lessonId': lessonRef,
      'youtubeUrl': 'u1',
      'youtubeVideoId': 'id1',
      'isProfilePrivate': false,
      'timestamp': Timestamp.fromMillisecondsSinceEpoch(10)
    });
    await fake.collection('progressVideos').doc('v2').set({
      'userId': userRef,
      'userUid': 'uid1',
      'courseId': courseRef,
      'lessonId': lessonRef,
      'youtubeUrl': 'u2',
      'youtubeVideoId': 'id2',
      'isProfilePrivate': false,
      'timestamp': Timestamp.fromMillisecondsSinceEpoch(20)
    });
    await fake.collection('progressVideos').doc('v3').set({
      'userId': userRef,
      'userUid': 'uid1',
      'courseId': courseRef,
      'lessonId': lessonRef,
      'youtubeUrl': 'u3',
      'youtubeVideoId': 'id3',
      'isProfilePrivate': true,
      'timestamp': Timestamp.fromMillisecondsSinceEpoch(30)
    });

    final snap = await ProgressVideoFunctions.streamCourseVideos('c1', limit: 2)
        .first;
    final videos =
        snap.docs.map((d) => ProgressVideo.fromSnapshot(d)).toList();
    expect(videos.length, 2);
    expect(videos.every((v) => !v.isProfilePrivate), isTrue);
    expect(videos.map((v) => v.id).toList(), ['v2', 'v1']);
  });

  test('fetchCourseVideos paginates results and excludes private videos',
      () async {
    final courseRef = docRef('courses', 'c1');
    final lessonRef = docRef('lessons', 'l1');
    final userRef = docRef('users', 'u1');

    await fake.collection('progressVideos').doc('v1').set({
      'userId': userRef,
      'userUid': 'uid1',
      'courseId': courseRef,
      'lessonId': lessonRef,
      'youtubeUrl': 'u1',
      'youtubeVideoId': 'id1',
      'isProfilePrivate': false,
      'timestamp': Timestamp.fromMillisecondsSinceEpoch(10)
    });
    await fake.collection('progressVideos').doc('v2').set({
      'userId': userRef,
      'userUid': 'uid1',
      'courseId': courseRef,
      'lessonId': lessonRef,
      'youtubeUrl': 'u2',
      'youtubeVideoId': 'id2',
      'isProfilePrivate': false,
      'timestamp': Timestamp.fromMillisecondsSinceEpoch(20)
    });
    await fake.collection('progressVideos').doc('v3').set({
      'userId': userRef,
      'userUid': 'uid1',
      'courseId': courseRef,
      'lessonId': lessonRef,
      'youtubeUrl': 'u3',
      'youtubeVideoId': 'id3',
      'isProfilePrivate': true,
      'timestamp': Timestamp.fromMillisecondsSinceEpoch(30)
    });

    final first = await ProgressVideoFunctions.fetchCourseVideos('c1', limit: 1);
    expect(first.docs.map((e) => e.id).toList(), ['v2']);
    final second = await ProgressVideoFunctions.fetchCourseVideos('c1',
        startAfter: first.docs.first, limit: 1);
    expect(second.docs.map((e) => e.id).toList(), ['v1']);
  });
}
