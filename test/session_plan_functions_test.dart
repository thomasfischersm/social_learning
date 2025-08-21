import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:social_learning/data/data_helpers/session_plan_functions.dart';
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

  test('create session plan', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final plan = await SessionPlanFunctions.create(courseId: 'c1', name: 'plan');
    expect(plan?.name, 'plan');
  });

  test('getOrCreateSessionPlanForCourse returns existing plan', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final created =
        await SessionPlanFunctions.create(courseId: 'c1', name: 'existing');

    final fetched =
        await SessionPlanFunctions.getOrCreateSessionPlanForCourse('c1');
    expect(fetched.id, created!.id);
    expect(fetched.name, 'existing');
  });

  test('getOrCreateSessionPlanForCourse creates when missing', () async {
    await fake.collection('courses').doc('c2').set({'title': 't2'});

    final plan =
        await SessionPlanFunctions.getOrCreateSessionPlanForCourse('c2');

    expect(plan.name, 'Session Plan');
    final byCourse = await SessionPlanFunctions.getByCourse('c2');
    expect(byCourse.length, 1);
  });

  test('updateSessionPlan renames plan', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final plan = await SessionPlanFunctions.create(courseId: 'c1', name: 'old');

    final updated = await SessionPlanFunctions.updateSessionPlan(
        sessionPlanId: plan!.id!, name: 'new');
    expect(updated?.name, 'new');

    final fetched = await SessionPlanFunctions.getById(plan.id!);
    expect(fetched?.name, 'new');
  });

  test('updateSessionPlan returns null for missing id', () async {
    final updated = await SessionPlanFunctions.updateSessionPlan(
        sessionPlanId: 'missing', name: 'name');
    expect(updated, isNull);
  });

  test('delete removes session plan', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final plan = await SessionPlanFunctions.create(courseId: 'c1', name: 'del');

    await SessionPlanFunctions.delete(plan!.id!);

    final byId = await SessionPlanFunctions.getById(plan.id!);
    expect(byId, isNull);
    final byCourse = await SessionPlanFunctions.getByCourse('c1');
    expect(byCourse, isEmpty);
  });

  test('getByCourse returns only plans for specified course', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    await fake.collection('courses').doc('c2').set({'title': 't2'});

    await SessionPlanFunctions.create(courseId: 'c1', name: 'p1');
    await SessionPlanFunctions.create(courseId: 'c1', name: 'p2');
    await SessionPlanFunctions.create(courseId: 'c2', name: 'p3');

    final c1Plans = await SessionPlanFunctions.getByCourse('c1');
    expect(c1Plans.map((p) => p.name).toList(), containsAll(['p1', 'p2']));
    expect(c1Plans.map((p) => p.name), isNot(contains('p3')));
  });

  test('getById fetches existing plan and returns null for missing', () async {
    await fake.collection('courses').doc('c1').set({'title': 't'});
    final plan = await SessionPlanFunctions.create(courseId: 'c1', name: 'plan');

    final fetched = await SessionPlanFunctions.getById(plan!.id!);
    expect(fetched?.name, 'plan');

    final missing = await SessionPlanFunctions.getById('missing');
    expect(missing, isNull);
  });
}
