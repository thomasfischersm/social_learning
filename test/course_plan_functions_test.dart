import 'package:cloud_firestore/cloud_firestore.dart';
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
    FirestoreService.instance = FirebaseFirestore.instance;
  });

  test('createCoursePlan then fetch by id', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final courseRef = fake.collection('courses').doc('c1');
    final id = await CoursePlanFunctions.createCoursePlan(courseRef, 'plan');
    final plan = await CoursePlanFunctions.getCoursePlanById(id);
    expect(plan?.planJson, 'plan');
  });
}
