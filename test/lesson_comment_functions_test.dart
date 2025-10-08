import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_learning/data/data_helpers/lesson_comment_functions.dart';
import 'package:social_learning/data/data_helpers/reference_helper.dart';
import 'package:social_learning/data/firestore_service.dart';
import 'package:social_learning/data/lesson.dart';
import 'package:social_learning/data/lesson_comment.dart';
import 'package:social_learning/data/user.dart';

void main() {
  final DocumentReference _courseRef = docRef('courses', 'course1');

  late FakeFirebaseFirestore fake;
  late Lesson lesson;
  late User user;

  setUp(() async {
    fake = FakeFirebaseFirestore();
    FirestoreService.instance = fake;

    lesson = Lesson(
      'lesson1',
      _courseRef,
      null,
      0,
      'Lesson 1',
      null,
      'Do this',
      null,
      null,
      null,
      null,
      null,
      false,
      'u1',
      [],
    );

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
    final snap = await fake.collection('users').doc('u1').get();
    user = User.fromSnapshot(snap);
  });

  tearDown(() {
    FirestoreService.instance = null;
  });

  test('addLessonComment writes a comment document', () async {
    await LessonCommentFunctions.addLessonComment(
        lesson, 'Great lesson', user);

    final snap = await fake.collection('lessonComments').get();
    expect(snap.docs.length, 1);

    final data = snap.docs.first.data();
    expect((data['lessonId'] as DocumentReference).path,
        'lessons/${lesson.id}');
    expect(data['text'], 'Great lesson');
    expect((data['creatorId'] as DocumentReference).path,
        'users/${user.id}');
    expect(data['creatorUid'], user.uid);
    expect(data['createdAt'], isA<Timestamp>());
  });

  test('deleteLessonComment removes the comment document', () async {
    final lessonRef = docRef('lessons', lesson.id!);
    final userRef = docRef('users', user.id);

    final doc = await fake.collection('lessonComments').add({
      'lessonId': lessonRef,
      'text': 'To be deleted',
      'creatorId': userRef,
      'creatorUid': user.uid,
      'createdAt': Timestamp.now(),
    });

    final comment = LessonComment(
      doc.id,
      lessonRef,
      _courseRef,
      'To be deleted',
      userRef,
      user.uid,
      null,
    );

    await LessonCommentFunctions.deleteLessonComment(comment);

    final exists = await fake.collection('lessonComments').doc(doc.id).get();
    expect(exists.exists, false);
  });
}

