import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_learning/data/data_helpers/practice_record_functions.dart';
import 'package:social_learning/data/firestore_service.dart';

void main() {
  late FakeFirebaseFirestore fake;

  setUp(() {
    fake = FakeFirebaseFirestore();
    FirestoreService.instance = fake;
  });

  tearDown(() {
    FirestoreService.instance = null;
  });

  test('getLessonsLearnedCount returns count of graduated lessons', () async {
    await fake.collection('practiceRecords').add({
      'menteeUid': 'u1',
      'isGraduation': true,
      'lessonId': fake.doc('lessons/l1'),
    });
    await fake.collection('practiceRecords').add({
      'menteeUid': 'u1',
      'isGraduation': true,
      'lessonId': fake.doc('lessons/l2'),
    });
    final count = await PracticeRecordFunctions.getLessonsLearnedCount('u1');
    expect(count, 2);
  });

  test('getLessonsLearnedCount returns 0 when no graduated lessons', () async {
    final count = await PracticeRecordFunctions.getLessonsLearnedCount('u1');
    expect(count, 0);
  });

  test('getLearnedLessonIds returns only graduated lesson references', () async {
    final lesson1 = fake.doc('lessons/l1');
    final lesson2 = fake.doc('lessons/l2');
    final lesson3 = fake.doc('lessons/l3');
    final course1 = fake.doc('courses/c1');
    final course2 = fake.doc('courses/c2');

    await fake.collection('practiceRecords').add({
      'menteeUid': 'u1',
      'mentorUid': 'm1',
      'courseId': course1,
      'lessonId': lesson1,
      'isGraduation': true,
    });
    await fake.collection('practiceRecords').add({
      'menteeUid': 'u1',
      'mentorUid': 'm2',
      'courseId': course1,
      'lessonId': lesson2,
      'isGraduation': false,
    });
    await fake.collection('practiceRecords').add({
      'menteeUid': 'u1',
      'mentorUid': 'm3',
      'courseId': course2,
      'lessonId': lesson3,
      'isGraduation': true,
    });

    final ids = await PracticeRecordFunctions.getLearnedLessonIds('u1');
    expect(ids, unorderedEquals([lesson1, lesson3]));
  });

  test('getLessonsTaughtCount returns count of graduated lessons for mentor',
      () async {
    final lesson1 = fake.doc('lessons/l1');
    final lesson2 = fake.doc('lessons/l2');
    await fake.collection('practiceRecords').add({
      'menteeUid': 'u1',
      'mentorUid': 'm1',
      'courseId': fake.doc('courses/c1'),
      'lessonId': lesson1,
      'isGraduation': true,
    });
    await fake.collection('practiceRecords').add({
      'menteeUid': 'u2',
      'mentorUid': 'm1',
      'courseId': fake.doc('courses/c2'),
      'lessonId': lesson2,
      'isGraduation': false,
    });
    await fake.collection('practiceRecords').add({
      'menteeUid': 'u3',
      'mentorUid': 'm2',
      'courseId': fake.doc('courses/c3'),
      'lessonId': fake.doc('lessons/l3'),
      'isGraduation': true,
    });

    final count = await PracticeRecordFunctions.getLessonsTaughtCount('m1');
    expect(count, 1);
  });

  test('getLessonsTaughtCount returns 0 when mentor has no graduations',
      () async {
    await fake.collection('practiceRecords').add({
      'menteeUid': 'u1',
      'mentorUid': 'm2',
      'courseId': fake.doc('courses/c1'),
      'lessonId': fake.doc('lessons/l1'),
      'isGraduation': true,
    });

    final count = await PracticeRecordFunctions.getLessonsTaughtCount('m1');
    expect(count, 0);
  });

  test('fetchPracticeRecordsForMentee returns all records for mentee',
      () async {
    final lesson1 = fake.doc('lessons/l1');
    final lesson2 = fake.doc('lessons/l2');
    await fake.collection('practiceRecords').add({
      'menteeUid': 'u1',
      'mentorUid': 'm1',
      'courseId': fake.doc('courses/c1'),
      'lessonId': lesson1,
      'isGraduation': true,
    });
    await fake.collection('practiceRecords').add({
      'menteeUid': 'u1',
      'mentorUid': 'm1',
      'courseId': fake.doc('courses/c1'),
      'lessonId': lesson2,
      'isGraduation': false,
    });
    await fake.collection('practiceRecords').add({
      'menteeUid': 'u2',
      'mentorUid': 'm1',
      'courseId': fake.doc('courses/c1'),
      'lessonId': fake.doc('lessons/l3'),
      'isGraduation': true,
    });

    final records =
        await PracticeRecordFunctions.fetchPracticeRecordsForMentee('u1');
    expect(records, hasLength(2));
    expect(records.map((r) => r.lessonId), unorderedEquals([lesson1, lesson2]));
    expect(records.map((r) => r.isGraduation), unorderedEquals([true, false]));
  });
}
