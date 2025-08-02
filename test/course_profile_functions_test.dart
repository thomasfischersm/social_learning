import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_learning/data/course_profile.dart';
import 'package:social_learning/data/data_helpers/course_profile_functions.dart';
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

  test('saveCourseProfile then load', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final profile = CourseProfile(
      courseId: fake.collection('courses').doc('c1'),
      topicAndFocus: 'topic',
      defaultTeachableItemDurationInMinutes: 10,
      instructionalTimePercent: 70,
    );
    final saved = await CourseProfileFunctions.saveCourseProfile(profile);
    expect(saved.courseId.path, 'courses/c1');
  });
}
