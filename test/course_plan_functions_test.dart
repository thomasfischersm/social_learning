import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_learning/data/data_helpers/course_plan_functions.dart';
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

  test('createCoursePlan then fetch by id', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final courseRef = fake.collection('courses').doc('c1');
    final id = await CoursePlanFunctions.createCoursePlan(courseRef, 'plan');
    final plan = await CoursePlanFunctions.getCoursePlanById(id);
    expect(plan?.planJson, 'plan');
  });

  test('getCoursePlanById returns null if missing', () async {
    final plan = await CoursePlanFunctions.getCoursePlanById('missing');
    expect(plan, isNull);
  });

  test('fetch by course reference', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final courseRef = fake.collection('courses').doc('c1');
    final id =
        await CoursePlanFunctions.createCoursePlan(courseRef, 'plan json');

    final plan = await CoursePlanFunctions.getCoursePlanByCourse(courseRef);

    expect(plan?.id, id);
    expect(plan?.planJson, 'plan json');
  });

  test('updatePlanJson updates the stored plan', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final courseRef = fake.collection('courses').doc('c1');
    final id =
        await CoursePlanFunctions.createCoursePlan(courseRef, 'original');

    await CoursePlanFunctions.updatePlanJson(id, 'updated');
    final plan = await CoursePlanFunctions.getCoursePlanById(id);

    expect(plan?.planJson, 'updated');
  });

  test('storeGeneratedJson saves generated output', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final courseRef = fake.collection('courses').doc('c1');
    final id = await CoursePlanFunctions.createCoursePlan(courseRef, 'plan');

    await CoursePlanFunctions.storeGeneratedJson(id, '{"levels": []}');
    final plan = await CoursePlanFunctions.getCoursePlanById(id);

    expect(plan?.generatedJson, '{"levels": []}');
  });
}
