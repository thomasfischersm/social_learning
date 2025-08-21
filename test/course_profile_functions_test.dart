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

  test('getCourseProfile returns saved profile with all fields', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final profile = CourseProfile(
      courseId: fake.collection('courses').doc('c1'),
      topicAndFocus: 'topic',
      defaultTeachableItemDurationInMinutes: 10,
      instructionalTimePercent: 70,
    );
    await CourseProfileFunctions.saveCourseProfile(profile);

    final fetched = await CourseProfileFunctions.getCourseProfile('c1');
    expect(fetched, isNotNull);
    expect(fetched!.topicAndFocus, 'topic');
    expect(fetched.defaultTeachableItemDurationInMinutes, 10);
    expect(fetched.instructionalTimePercent, 70);
  });

  test('getCourseProfile returns null when no profile exists', () async {
    await fake.collection('courses').doc('c2').set({'title': 't2'});
    final fetched = await CourseProfileFunctions.getCourseProfile('c2');
    expect(fetched, isNull);
  });

  test('saveCourseProfile updates existing profile when id provided', () async {
    await fake.collection('courses').doc('c3').set({'title': 't3'});
    final initial = CourseProfile(
      courseId: fake.collection('courses').doc('c3'),
      topicAndFocus: 'old',
      defaultTeachableItemDurationInMinutes: 10,
      instructionalTimePercent: 70,
    );
    final saved = await CourseProfileFunctions.saveCourseProfile(initial);

    final updated = CourseProfile(
      id: saved.id,
      courseId: saved.courseId,
      topicAndFocus: 'new',
      defaultTeachableItemDurationInMinutes: 15,
      instructionalTimePercent: 80,
    );
    final result = await CourseProfileFunctions.saveCourseProfile(updated);

    expect(result.id, saved.id);
    expect(result.topicAndFocus, 'new');
    expect(result.defaultTeachableItemDurationInMinutes, 15);
    expect(result.instructionalTimePercent, 80);

    final allProfiles = await fake.collection('courseProfiles').get();
    expect(allProfiles.docs.length, 1);
  });
}
