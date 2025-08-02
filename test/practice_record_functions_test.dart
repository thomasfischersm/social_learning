import 'package:cloud_firestore/cloud_firestore.dart';
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
}
