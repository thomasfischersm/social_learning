import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_learning/data/data_helpers/session_plan_block_functions.dart';
import 'package:social_learning/data/data_helpers/session_plan_functions.dart';
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

  test('create session plan block', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final plan = await SessionPlanFunctions.create(courseId: 'c1', name: 'p');
    final block = await SessionPlanBlockFunctions.create(
        courseId: 'c1', sessionPlanId: plan!.id!, name: 'b', sortOrder: 0);
    expect(block?.name, 'b');
  });
}
